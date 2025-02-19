/*
 * SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { EventEmitter, once } from "node:events";
import getLogger from "../logger.js";
import AbstractTask from "./AbstractTask.js";
import { InteractionMode } from "../../../shared/types.js";
import sleep from "../../utils/sleep.js";
import HTTPClient from "../clients/HTTPClient.js";
import { randomUUID } from "node:crypto";
import { HTTP_CHAT_URL } from "../../config.js";

const logger = getLogger("HTTPChatTask");

// Fetching the bot lists sometimes fails with transient issues. This sets the number
// of retries allowed. Once retries are exhausted, a fatal error is emitted
const MAX_RETRIES = 3;

/**
 * Handles text conversations between the user and the bot using ACE Agent's HTTP
 * interface. This only runs when ACE Agent runs in "server" mode. In other modes (speech
 * or event), the UMIMTask or GRPCTextTask take care of handling text conversations.
 *
 * This task has two main responsibilities:
 * 1. Send the user's text messages to the bot through ACE Agent's HTTP interface, and
 *    emit the bot's response through the shared event bus for other tasks to handle
 * 2. Poll the list of available bots. ACE Agent's HTTP interface supports multiple bots,
 *    so the UI needs to show a dropdown of all available bots.
 */
export default class HTTPChatTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [InteractionMode.TEXT];

  constructor(eventBus: EventEmitter, private readonly streamID: string) {
    super(eventBus);
  }

  public override async start(): Promise<void> {
    super.start();
    logger.info("starting running task");
    try {
      await Promise.all([this.getBotList(), this.listenUserFinishedMessage()]);
    } catch (e) {
      if (e.name === "AbortError") {
        // Task was stopped while listening on the eventBus. This is OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Polls the list of available bots from ACE Agent's HTTP interface. When the list of
   * bots change, it is emitted through the shared event bus for other tasks to handle.
   */
  public async getBotList(): Promise<void> {
    let botList = [];
    let retries = MAX_RETRIES;
    while (this.isRunning()) {
      try {
        const data = await HTTPClient.get().fetch("/isReady", {
          signal: this.abortController.signal,
        });

        const bots = (await data.json()) as any[];
        const newBotList = bots
          .filter((bot) => bot.Ready)
          .map((bot) => bot.BotName);

        if (newBotList.join() !== botList.join()) {
          this.eventBus.emit("botListUpdated", newBotList);
          botList = newBotList;
        }
        retries = MAX_RETRIES;
      } catch (e) {
        // A common transient error, retry
        if (
          e.code === "ECONNRESET" ||
          (e.code === "ECONNREFUSED" && retries > 0)
        ) {
          retries--;
          logger.warn(
            `Received error "%s" while fetching list of bots. Retrying (retries left: ${retries})`,
            e.code
          );
          continue;
        }
        logger.fatal("Caught error while running task", e);
        this.eventBus.emit("fatalError", this.constructor.name, e);
      }

      await sleep(1000);
    }

    this.eventBus.emit("botListUpdated", []);
  }

  /**
   * Continuously listens for the user submitting full messages. Partial messages are
   * ignored.
   */
  private async listenUserFinishedMessage(): Promise<void> {
    while (this.isRunning()) {
      const [_, text, botName] = await once(
        this.eventBus,
        "userFinishedMessage",
        this.abortController
      );
      this.handleUserFinishedMessage(text, botName);
    }
  }

  /**
   * Handles a new message that was submitted by the user. When a new message is
   * available, it is sent to the bot through ACE Agent's HTTP interface. The bot's
   * response is emitted through the shared event listeners for other tasks to handle.
   * @param text the user's text message
   * @param botName the name of the bot to use
   */
  private async handleUserFinishedMessage(
    text: string,
    botName: string | null
  ): Promise<void> {
    const parameters = {
      Query: text,
      UserId: this.streamID,
      BotName: botName,
    };
    this.eventBus.emit("botStartedThinkingIdle", randomUUID());
    const response = await HTTPClient.get().fetch("/chat", {
      method: "POST",
      signal: this.abortController.signal,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(parameters),
    });
    if (response.status !== 200) {
      const error = new Error(
        `Received unexpected HTTP response status ${response.status} from ACE Agent's ${HTTP_CHAT_URL}/chat endpoint. This typically happens when the Chat Engine service has not been started, or has stopped running. Refresh the page to try again`
      );
      logger.error(error.message);
      this.eventBus.emit("fatalError", this.constructor.name, error);
      return;
    }
    const transferEncoding = response.headers.get("Transfer-Encoding");
    if (transferEncoding === "chunked") {
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let result = await reader.read();
      let text = "";
      let queryID = "";
      while (!result.done) {
        const partialText = decoder.decode(result.value);
        const parsed = JSON.parse(partialText);
        text += parsed.Response.CleanedText ?? "";
        queryID = parsed.Metadata.QueryId;
        result = await reader.read();
      }
      this.eventBus.emit("botStartedUtterance", queryID, text, botName);
    } else {
      const json = (await response.json()) as { Metadata: any; Response: any };
      this.eventBus.emit(
        "botStartedUtterance",
        json.Metadata.QueryId,
        json.Response.CleanedText,
        botName
      );
    }
  }
}
