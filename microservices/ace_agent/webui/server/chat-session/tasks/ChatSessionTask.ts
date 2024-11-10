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

import { randomUUID } from "crypto";
import EmojiFinder from "../../emoji-finder/index.js";
import { WebSocket } from "ws";
import AbstractTask from "./AbstractTask.js";
import UMIMTask from "./UMIMTask.js";
import { EventEmitter } from "node:events";
import GRPCSpeechTask from "./GRPCSpeechTask.js";
import WebSocketTask from "./WebSocketTask.js";
import getLogger from "../logger.js";
import { once } from "events";
import {
  InteractionMode,
  ServerConfig,
  SystemMessageContent,
} from "../../../shared/types.js";
import GRPCTextTask from "./GRPCTextTask.js";
import HTTPChatTask from "./HTTPChatTask.js";
import GRPCClient from "../clients/GRPCClient.js";
import HTTPClient from "../clients/HTTPClient.js";
import RedisClient from "../clients/RedisClient.js";
import sleep from "../../utils/sleep.js";
import GRPCSpeechTranscriptionTask from "./GRPCSpeechTranscriptionTask.js";

const logger = getLogger("ChatSessionTask");

/**
 * This task is responsible for managing other tasks. It is started as soon as a user
 * starts a new session (in other words: when a websocket connection is made to the
 * server). It checks which clients (gRPC, Redis or HTTP) are available, and instantiates
 * tasks that are compatible with these clients.
 *
 * Whenever the user switches interaction mode (text or speech), this task starts and stop
 * other tasks depending on whether they support the desired mode.
 *
 * When the user leaves the session (closes the tab), this tasks stops all other tasks,
 * and cleans them up before stoppping itself.
 */
export default class ChatSessionTask extends AbstractTask {
  public interactionModes: InteractionMode[] = [
    InteractionMode.SPEECH,
    InteractionMode.TEXT,
  ];

  /**
   * Stream ID identifies a user's session across API calls.
   */
  private readonly streamID: string = randomUUID();

  /**
   * List of tasks running for the user's session. Typically contains all tasks that are
   * compatible with the available clients (Redis, gRPC, HTTP).
   */
  private tasks: AbstractTask[] = [];

  /**
   * Constructor
   * @param ws the websocket connection for the user's session
   * @param emojiFinder the "emojiFinder" instance. Only used for UMIM (redis) tasks
   * @param aceAgentTextChatInterface the mode in which ACE Agent is running
   * @param isSpeechEnabled whether the bot web UI should allow speech conversations (
   *                        ACE Agent must be running in speech mode)
   */
  constructor(
    readonly ws: WebSocket,
    readonly emojiFinder: EmojiFinder | null,
    readonly aceAgentTextChatInterface: "server" | "grpc" | "event",
    readonly isSpeechEnabled: boolean
  ) {
    super(new EventEmitter());
    this.initTasks();
  }

  /**
   * Called when the user leaves the session. This cleanes up all tasks running for the
   * user's session.
   */
  public override async cleanup(): Promise<void> {
    this.tasks.forEach(async (task) => {
      try {
        await task.cleanup();
      } catch (e) {
        logger.warn(
          `Received exception while cleaning up ${task.constructor.name}. Ignoring`,
          e
        );
      }
    });
  }

  /**
    Runs the main logic for the chat session. This starts all available tasks in text mode
    (the default mode).
   */
  public override async start(): Promise<void> {
    super.start();
    try {
      await Promise.all([
        this.listenFatalErrors(),
        this.listenWebSocketClosed(),
        this.listenWebServerStopped(),
        this.listenUserToggledSpeech(),
        this.refreshTasks(InteractionMode.TEXT),
        this.sendServerConfig(),
      ]);
    } catch (e) {
      if (e.name === "AbortError") {
        // The task was stopped while it was listening for events on the eventsBus. This
        // is OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Instantiates all tasks (but does not run them). Only tasks compatible with available
   * clients (gRPC, Redis or HTTP) are instantiated
   */
  private initTasks(): void {
    const redisAvailable = RedisClient.isAvailable();
    const gRPCAvailable = GRPCClient.isAvailable();
    const httpAvailable = HTTPClient.isAvailable();

    this.enableWebSocketTask();

    switch (this.aceAgentTextChatInterface) {
      case "grpc":
        if (!gRPCAvailable) {
          throw new Error(
            "Program was run with --ace-agent-text-chat-interface=grpc, but no GRPC_URL environment variable was set."
          );
        }
        this.enableGRPCTextTask();
        break;
      case "event":
        if (!redisAvailable) {
          throw new Error(
            "Program was run with --ace-agent-text-chat-interface=event, but no REDIS_URL environment variable was set."
          );
        }
        this.enableUMIMTask();
        break;
      case "server":
        if (!httpAvailable) {
          throw new Error(
            "Program was run with --ace-agent-text-chat-interface=server, but no HTTP_CHAT_URL environment variable was set."
          );
        }
        this.enableHTTPChatTask();
        break;
    }

    if (this.isSpeechEnabled) {
      if (gRPCAvailable) {
        this.enableGRPCSpeechTask();

        // In event mode, the UMIMTask is already handling speech transcriptions. Only
        // enable gRPC speech transcriptions when not in event mode
        if (this.aceAgentTextChatInterface !== "event") {
          this.enableGRPCBotSpeechTranscriptionTask();
        }
      } else {
        throw new Error(
          "Program was run with --speech, but no GRPC_URL environment variable was set."
        );
      }
    }
  }

  /**
   * Enable the UMIM task.
   */
  private enableUMIMTask(): void {
    logger.info("Enabling UMIMTask");
    this.tasks.push(new UMIMTask(this.eventBus, this.getStreamID()));
  }

  /**
   * Enable the GRPC Speech task. This sets isSpeechEnabled=true. It is the only task that
   * is required to support speech mode
   */
  private enableGRPCSpeechTask(): void {
    logger.info("Enabling GRPCSpeechTask");
    this.tasks.push(new GRPCSpeechTask(this.eventBus, this.getStreamID()));
  }

  /**
   * Enables the GRPC Text task.
   */
  private enableGRPCTextTask(): void {
    logger.info("Enabling GRPCTextTask");
    this.tasks.push(new GRPCTextTask(this.eventBus, this.getStreamID()));
  }

  /**
   * Enables the GRPC Bot Speech Transcription Task.
   */
  private enableGRPCBotSpeechTranscriptionTask(): void {
    logger.info("Enabling GRPCSpeechTranscriptionTask");
    this.tasks.push(
      new GRPCSpeechTranscriptionTask(this.eventBus, this.getStreamID())
    );
  }

  /**
   * Enables the HTTP Chat task
   */
  private enableHTTPChatTask(): void {
    logger.info("Enabling HTTPChatTask");
    this.tasks.push(new HTTPChatTask(this.eventBus, this.getStreamID()));
  }

  /**
   * Enables the Websocket task
   */
  private enableWebSocketTask(): void {
    logger.info("Enabling WebSocketTask");
    this.tasks.push(
      new WebSocketTask(this.eventBus, this.emojiFinder, this.ws)
    );
  }

  /**
   * Starts and stops task, depending on whether they are compatible with the user's
   * desired interaction mode (text or speech).
   * @param interactionMode the user's desired interaction mode
   */
  private refreshTasks(interactionMode: InteractionMode): void {
    for (const task of this.tasks) {
      const shouldRun = task.interactionModes.includes(interactionMode);
      if (task.isRunning() && !shouldRun) {
        logger.info(
          "Stopping task %s because it is not needed in new interaction mode",
          task.constructor.name,
          interactionMode
        );
        task.stop();
      }
      if (!task.isRunning() && shouldRun) {
        logger.info(
          "Starting task %s because it is needed in new interaction mode",
          task.constructor.name,
          interactionMode
        );
        task.start();
      }
    }
  }

  /**
   * Informs other tasks whether the current session supports speech
   */
  private sendServerConfig(): void {
    const serverConfig: ServerConfig = {
      type: SystemMessageContent.CONFIG_CHANGE,
      speechSupported: this.isSpeechEnabled,
    };
    this.eventBus.emit("serverConfigChange", serverConfig);
  }

  /**
   * Listens for when the user closed the websocket (closed window/tab). When this
   * happens, all running tasks are closed.
   */
  private async listenWebSocketClosed(): Promise<void> {
    await once(this.eventBus, "userClosedSocket", this.abortController);
    logger.info("User closed the websocket. Stopping all tasks");
    this.stop();
    await this.cleanup();
  }

  /**
   * Listens for when the process is killed or restarted (e.g. hot-reloading). This stops
   * all running tasks for the session
   */
  private async listenWebServerStopped(): Promise<void> {
    await once(process, "SIGTERM", this.abortController);
    logger.info(
      "SIGTERM signal received. Stopping session and existing program"
    );
    this.stop();
    await this.cleanup();
    await sleep(1000); // Grace period for other sessions to shutdown
    process.exit();
  }

  /**
   * Continuously listens for when the user toggles speech or text mode.
   */
  private async listenUserToggledSpeech(): Promise<void> {
    while (this.isRunning()) {
      const [interactionMode] = await once(
        this.eventBus,
        "userToggledSpeech",
        this.abortController
      );

      this.handleUserToggledSpeech(interactionMode);
    }
  }

  /**
   * Continuously listens for fatal errors from other tasks
   */
  private async listenFatalErrors(): Promise<void> {
    while (this.isRunning()) {
      const [taskName, error] = await once(
        this.eventBus,
        "fatalError",
        this.abortController
      );
      this.handleFatalError(taskName, error);
    }
  }

  /**
   * Called when the user toggles speech mode. When the user enables speech mode, this
   * starts the speech-related tasks (ASR, streaming audio, etc). When the user turns
   * speech mode off, this stops speech-related tasks.
   * @param interactionMode the user's desired interaction mode (text or speech)
   */
  private async handleUserToggledSpeech(
    interactionMode: InteractionMode
  ): Promise<void> {
    logger.info(
      "User toggled interaction mode to %s. Refreshing tasks",
      interactionMode
    );
    this.refreshTasks(interactionMode);
  }

  /**
   * Handler for when a task emits a fatal error. When this happens, a message is sent
   * to the client to inform the user, and all tasks for the current session are terminated.
   */
  private handleFatalError(taskName: string, error: Error): void {
    logger.info(`Sending fatal ${error.name} information to user`);
    this.eventBus.emit(
      "shutdown",
      `A fatal error occurred while running task ${taskName}. Message: "${error.message}". Check the server logs for more details.`
    );
    this.stop();
  }

  /**
   * Stops all speech and text related tasks. This is typically called when the user
   * leaves the session (e.g. closes tab).
   */
  stop(): void {
    logger.info("Informing user that the session is being shut down");
    this.eventBus.emit(
      "shutdown",
      "The server shut down. Please refresh this page to start a new session."
    );
    super.stop();
    for (const task of this.tasks) {
      if (task.isRunning()) {
        task.stop();
      }
    }
  }

  /**
   * The stream ID for this session. A stream ID is unique to each session, and identifies
   * the UMIM/gRPC pipeline for the conversation
   * @returns the stream ID
   */
  public getStreamID(): string {
    return this.streamID;
  }
}
