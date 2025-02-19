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

import AbstractTask from "./AbstractTask.js";
import { EventEmitter, once } from "node:events";
import getLogger from "../logger.js";
import { randomUUID } from "node:crypto";
import { InteractionMode } from "../../../shared/types.js";
import GRPCClient from "../clients/GRPCClient.js";

const logger = getLogger("GRPCTextTask");

/**
 * This task is responsible for handling text conversations between the user and the bot.
 * When a new text message is sent by the user, this task sends it to ACE Agent. ACE Agent
 * then respond with the bot's text response, which the task emits on the shared event bus
 * for other tasks to handle.
 *
 * This task only runs when ACE Agent runs in "speech" mode (in "event" mode, the UMIMTask
 * takes care of handling text conversations).
 */
export default class GRPCTextTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [InteractionMode.TEXT];
  private readonly gRPCClient = GRPCClient.get();
  private pipelineAcquired: boolean = false;

  constructor(eventBus: EventEmitter, private readonly streamID: string) {
    super(eventBus);
  }

  public override async cleanup(): Promise<void> {
    if (this.pipelineAcquired) {
      await this.informGRPCPipelineReleased();
    }
  }

  public override async start(): Promise<void> {
    super.start();

    try {
      if (!this.pipelineAcquired) {
        logger.info("Acquiring gRPC pipeline");
        this.pipelineAcquired = true;
        await this.informGRPCPipelineAcquired();
      }
      await this.listenUserFinishedMessage();
    } catch (e) {
      if (e.name === "AbortError") {
        // The task was stopped while listening for events on the eventBus. This is OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Continuously listens for the user submitting "full" messages (in other words, when
   * the user submits the message from the UI). Partial messages are ignored.
   */
  private async listenUserFinishedMessage(): Promise<void> {
    while (this.isRunning()) {
      const [_messageID, text] = await once(
        this.eventBus,
        "userFinishedMessage",
        this.abortController
      );
      await this.handleUserFinishedMessage(text);
    }
  }

  /**
   * Handles a new message submitted by the user. The message is sent to ACE Agent through
   * its gRPC interface. The bot's response is emitted through the shared event listeners
   * for other tasks to handle.
   * @param text the user's text message
   */
  private async handleUserFinishedMessage(text: string): Promise<void> {
    const queryID = randomUUID();
    const response = this.gRPCClient.chat({
      streamId: this.streamID,
      query: text,
      queryId: queryID,
      isStandalone: true,
    });

    let responseText = "";
    for await (const chunk of response) {
      logger.info("received chat response", chunk.cleanedText);
      responseText += chunk.cleanedText;
    }
    this.eventBus.emit("botStartedUtterance", queryID, responseText, null);
  }

  /**
   * Informs ACE Agent that the user has started a session.
   */
  private async informGRPCPipelineAcquired(): Promise<void> {
    await this.gRPCClient.createPipeline({
      streamId: this.streamID,
      userId: this.streamID,
    });
  }

  /**
   * Informs ACE Agent that the user has left the session. This should be called when the
   * task is cleaned up.
   */
  private async informGRPCPipelineReleased(): Promise<void> {
    await this.gRPCClient.freePipeline({
      streamId: this.streamID,
      userId: this.streamID,
    });
  }
}
