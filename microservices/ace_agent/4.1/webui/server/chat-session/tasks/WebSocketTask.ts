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

import { RawData, WebSocket } from "ws";
import {
  AuthorType,
  BotChatMessage,
  ChatMessageContentType,
  InteractionMode,
  MessageID,
  ServerConfig,
  SystemConfigMessage,
  SystemMessageContent,
  SystemShutdownMessage,
  UserChatMessage,
} from "../../../shared/types.js";
import AbstractTask from "./AbstractTask.js";
import { EventEmitter, once } from "node:events";
import EmojiFinder from "../../emoji-finder/index.js";
import getLogger from "../logger.js";

const logger = getLogger("WebSocketTask");

/**
 * This task handles the websocket connection with the user. It's responsible for
 * listening to incoming messages from the user, and sending messages back to the user.
 * It communicate with other tasks through the shared event bus.
 */
export default class WebSocketTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [
    InteractionMode.SPEECH,
    InteractionMode.TEXT,
  ];

  constructor(
    eventBus: EventEmitter,
    private readonly emojiFinder: EmojiFinder | null,
    private readonly ws: WebSocket
  ) {
    super(eventBus);
  }

  /**
   * Runs all the listening loops (listen to websocket messages, bot messages, etc).
   */
  public override async start(): Promise<void> {
    super.start();
    try {
      await Promise.all([
        this.listenServerConfigChange(),
        this.listenWebSocketMessages(),
        this.listenWebSocketError(),
        this.listenWebSocketClose(),
        this.listenBotListUpdated(),
        this.listenBotStartedUtterance(),
        this.listenBotStartedThinkingIdle(),
        this.listenBotStartedGesture(),
        this.listenBotSentAudio(),
        this.listenASRAvailable(),
        this.listenUserBargeIn(),
        this.listenShutdown(),
      ]);
    } catch (e) {
      if (e.name === "AbortError") {
        // Task was stopped while listening for messages on the event bus. That's OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Continuously listens to incoming websocket messages from the user until the task
   * is stopped.
   */
  private async listenWebSocketMessages(): Promise<void> {
    while (this.isRunning()) {
      const [data] = await once(this.ws, "message", this.abortController);
      this.handleWebSocketMessage(data);
    }
  }

  /**
   * Continuously listens for websocket errors, until the task is stopped.
   */
  private async listenWebSocketError(): Promise<void> {
    while (this.isRunning()) {
      const [error] = await once(this.ws, "error", this.abortController);
      this.handleWebSocketError(error);
    }
  }

  /**
   * Listens for the websocket being closed.
   */
  private async listenWebSocketClose(): Promise<void> {
    const [code] = await once(this.ws, "close", this.abortController);
    this.handleWebSocketClosed(code);
  }

  /**
   * Continuously listens for a new list of bots being available. This happens when the
   * ACE Agent runs in "server" mode with multiple bots enabled.
   */
  private async listenBotListUpdated(): Promise<void> {
    while (this.isRunning()) {
      const [botList] = await once(
        this.eventBus,
        "botListUpdated",
        this.abortController
      );
      this.handleBotListUpdated(botList);
    }
  }

  /**
   * Continuously listens for bot utterances from the shared event bus.
   */
  private async listenBotStartedUtterance(): Promise<void> {
    while (this.isRunning()) {
      const [actionID, transcript, botName] = await once(
        this.eventBus,
        "botStartedUtterance",
        this.abortController
      );
      this.handleBotStartedUtterance(actionID, transcript, botName);
    }
  }

  /**
   * Continuously listens for "the bot is thinking" events from the shared event bus.
   */
  private async listenBotStartedThinkingIdle(): Promise<void> {
    while (this.isRunning()) {
      const [actionID] = await once(
        this.eventBus,
        "botStartedThinkingIdle",
        this.abortController
      );
      this.handleBotStartedThinkingIdle(actionID);
    }
  }

  /**
   * Continuously listens for bot gestures from the shared event bus.
   */
  private async listenBotStartedGesture(): Promise<void> {
    while (this.isRunning()) {
      const [actionID, gesture, botName] = await once(
        this.eventBus,
        "botStartedGesture",
        this.abortController
      );
      this.handleBotStartedGesture(actionID, gesture, botName);
    }
  }

  /**
   * Continuously listens for audio sent by the bot through the shared event bus.
   */
  private async listenBotSentAudio(): Promise<void> {
    while (this.isRunning()) {
      const [audio] = await once(
        this.eventBus,
        "botSentAudio",
        this.abortController
      );
      this.handleBotSentAudio(audio);
    }
  }

  /**
   * Continuously listens for new ASR data from the shared event emitter
   */
  private async listenASRAvailable(): Promise<void> {
    while (this.isRunning()) {
      const [text, messageID] = await once(
        this.eventBus,
        "asrAvailable",
        this.abortController
      );
      this.handleASRAvailable(text, messageID);
    }
  }

  /**
   * Continuously listens for user barge-ins. A barge-in is when the user interrupts
   * the bot while the bot is speaking. Barge-in are detected by ACE Agent
   */
  private async listenUserBargeIn(): Promise<void> {
    while (this.isRunning()) {
      await once(this.eventBus, "userBargeIn", this.abortController);
      this.handleUserBargeIn();
    }
  }

  /**
   * Continuously listens for a shutdown signal. The shutdown event signals that the
   * session has stopped
   */
  private async listenShutdown(): Promise<void> {
    while (this.isRunning()) {
      const [reason] = await once(
        this.eventBus,
        "shutdown",
        this.abortController
      );
      this.handleShutdown(reason);
    }
  }

  /**
   * Continuously listens for "server" config updates. This typically happens when the
   * server needs to advertise a configuration that the client needs to know. For example,
   * this is used to inform the client whether the server supports speech mode.
   */
  private async listenServerConfigChange(): Promise<void> {
    while (this.isRunning()) {
      const [serverConfig] = await once(
        this.eventBus,
        "serverConfigChange",
        this.abortController
      );
      this.handleServerConfigChange(serverConfig);
    }
  }

  /**
   * Handler for when the user sends a new message through the websocket.
   *
   * If the data looks like audio (is a binary ArrayBuffer), assumes the user is sending
   * audio.
   *
   * Otherwise, the handler parses the message as a JSON string, and sends the content of
   * the message through the shared event emitter for other tasks to handle:
   * 1. "userStartedNewMessage" if the user just started typing a new message
   * 2. "userUpdatedMessage" if the user updated an existing message (typically, the
   *    message is updated on every key stroke until it's actually sent)
   * 3. "userFinishedMessage" if the user submitted their message
   * @param data an audio chunk or a JSON-encoded string
   */
  private handleWebSocketMessage(data: RawData): void {
    if (data instanceof ArrayBuffer) {
      logger.info("Received audio message from user");
      this.eventBus.emit("userSentAudio", data);
      return;
    }

    let message;
    try {
      message = JSON.parse(data.toString()) as UserChatMessage;
    } catch (e) {
      logger.error("Could not parse the message as audio or JSON. Ignoring", e);
      return;
    }

    logger.info(
      "Received text of type %s message from user",
      message.content.type
    );

    switch (message.content.type) {
      case ChatMessageContentType.TYPING: {
        if (message.content.isNewMessage) {
          this.eventBus.emit(
            "userStartedNewMessage",
            message.content.messageID
          );
        } else {
          this.eventBus.emit(
            "userUpdatedMessage",
            message.content.messageID,
            message.content.text
          );
        }
        break;
      }
      case ChatMessageContentType.TEXT:
        this.eventBus.emit(
          "userFinishedMessage",
          message.content.messageID,
          message.content.text,
          message.content.botName
        );
        break;
      case ChatMessageContentType.TOGGLE_SPEECH:
        this.eventBus.emit(
          "userToggledSpeech",
          message.content.interactionMode
        );
        break;
    }
  }

  /**
   * Handles a new list of bots shared by ACE Agent. This happens when ACE Agent runs
   * in `server` mode, and runs multiple bots in parallel. The list of bots is sent to the
   * client, so that the user can select which bot they'd like to converse with from a
   * dropdown in the UI.
   * @param botList the list of bots
   */
  private handleBotListUpdated(botList: string[]): void {
    logger.info("Sending updated botlist to user", botList);
    const message: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.BOT_LIST,
        botList,
      },
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * Handler for when the bot sent an utterance. Sends the utterance in text form to the
   * browser through the websocket.
   * @param actionID the ID for the bot action
   * @param transcript the text sent by the bot
   */
  private handleBotStartedUtterance(
    actionID: string,
    transcript: string,
    botName: string | null
  ): void {
    this.sendTextMessageToUser(actionID, transcript, botName);
  }

  /**
   * Handler for when the bot signals its "thinking". Informs the user that the bot is
   * "typing".
   * @param actionID the ID for the action
   */
  private handleBotStartedThinkingIdle(actionID: string): void {
    logger.info("Received bot thinking/idle");
    this.sendTypingMessageToUser(actionID);
  }

  /**
   * Handler for when the bot sends a gesture. The handler tries to translate the gesture
   * into an emoji, and sends this emoji to the user through the websocket.
   * @param actionID ID for the action
   * @param gesture text description for the gesture (e.g. "wave hands")
   */
  private async handleBotStartedGesture(
    actionID: string,
    gesture: string,
    botName: string | null
  ): Promise<void> {
    logger.info("Received gesture %s from bot", gesture);

    const emoji = await this.emojiFinder?.findEmoji(gesture);
    if (!emoji) {
      logger.warn(
        'Could not translate gesture "%s" into an emoji. Ignoring',
        gesture
      );
      return;
    }

    logger.info("Found emoji %s for gesture", emoji.emoji, gesture);
    this.sendEmojiMessageToUser(actionID, emoji.emoji, gesture, botName);
  }

  /**
   * Handler for when the bot sends an audio chunk. The audio chunk is immediately sent
   * to the client.
   * @param audio the audio chunk
   */
  private handleBotSentAudio(audio: Uint8Array): void {
    logger.info("Received audio chunk (length=%s) from bot", audio.length);
    this.sendAudioChunkToUser(audio);
  }

  /**
   * Handler for when ASR data is available (ie. how the bot converts the speech to
   * text). This information is sent to the user through the websocket, so that the UI
   * can show what the bot thinks the user is saying.
   * @param text the bot's best guess of what the user is currently saying
   * @param messageID the ID of the message, if updating an existing utterance
   */
  private handleASRAvailable(text: string, messageID: string): void {
    logger.info("Received ASR. Sending to user", text, messageID);
    this.sendASRToUser(text, messageID);
  }

  /**
   * Handler for when a user barge-in is detected. This is when the user interrupts
   * the bot while it's speaking. When this happens, the UI should immediately interrupt
   * the bot's audio speech for a snappy experience.
   */
  private handleUserBargeIn(): void {
    logger.info(
      "Detected user barge-in. Informing UI so that it can interrupt its audio buffer"
    );
    this.sendUserBargeInToUser();
  }

  /**
   * Handles a server config change. For example, when the server wants to advertise that
   * it supports speech mode. the config is immediately sent to the client.
   * @param serverConfig
   */
  private handleServerConfigChange(serverConfig: ServerConfig): void {
    logger.info("Server config has changed. Sending new config to user");
    this.sendServerConfigToUser(serverConfig);
  }

  /**
   * Handler for when the websocket is closed. This typically happens when the user closes
   * their browser tab. This emits a `userClosedSocket` event on the shared event emitter,
   * allowing the chat-session to close all tasks gracefully.
   * @param code the error code
   */
  private handleWebSocketClosed(code: number): void {
    logger.info("Websocket was closed with code", code);
    this.eventBus.emit("userClosedSocket");
  }

  /**
   * Handler for errors received through the websocket. Logs the error, nothing more.
   * @param error
   */
  private handleWebSocketError(error: Error): void {
    logger.error("received error from websocket", error);
  }

  /**
   * Handles the session shutdown signal. Informs the user of the reason for the shutdown
   * @param reason
   */
  private handleShutdown(reason: string): void {
    logger.info(
      "Session shutdown signal received. Informing user. Reason:",
      reason
    );
    this.sendShutdownSignalToUser(reason);
  }

  /**
   * Sends a text message to the user using the websocket to their browser.
   * @param messageID the ID for the message
   * @param text the text of the message
   * @param botName when mutliple bots run in parallel, set the name of the bot that sent
   *                this message
   */
  private sendTextMessageToUser(
    messageID: MessageID,
    text: string,
    botName: string | null
  ): void {
    logger.info("Sending text to user:", text);
    const message: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.TEXT,
        messageID,
        text,
        botName,
      },
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * sends a "system" message. System messages are used to communicate information to the
   * user, such as the state of the session.
   * @param serverConfig the new server config
   */
  private sendServerConfigToUser(serverConfig: ServerConfig): void {
    const message: SystemConfigMessage = {
      author: AuthorType.SYSTEM,
      content: serverConfig,
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * Informs the user that the session is being shutdown
   * @param reason
   */
  private sendShutdownSignalToUser(reason: string): void {
    const message: SystemShutdownMessage = {
      author: AuthorType.SYSTEM,
      content: {
        type: SystemMessageContent.SHUTDOWN,
        reason,
      },
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * Sends an emoji message to the user.
   * @param messageID ID for the message
   * @param emoji the emoji in unicode character
   * @param title a string representing the emoji
   * @param botName when multiple bots are running in parallel, set the name of the bot
   *                that sent the emoji
   */
  private sendEmojiMessageToUser(
    messageID: MessageID,
    emoji: string,
    title: string,
    botName: string | null
  ): void {
    logger.info("Sending emoji user", emoji, title);
    const message: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.EMOJI,
        messageID,
        emoji,
        title,
        botName,
      },
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * Sends a "typing" message to the user, to inform that the bot is preparing a reply.
   * @param actionUID the ID of the action associated with the message
   */
  private sendTypingMessageToUser(actionUID: string): void {
    logger.info('Sending "typing" signal to user');
    const message: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.TYPING,
        messageID: actionUID,
        text: "",
        isNewMessage: true,
      },
    };
    this.ws.send(JSON.stringify(message));
  }

  /**
   * Sends a chunk of audio to the user's browser.
   * @param buffer the audio content in binary form
   */
  private sendAudioChunkToUser(buffer: Uint8Array): void {
    this.ws.send(buffer);
  }

  /**
   * Sends the latest ASR for the user's speech. It is the text that the bot believes is
   * the most probable utterance that the user is saying.
   * @param transcript what the bot thinks the user is saying
   * @param messageID the ID of the message being updated
   */
  private sendASRToUser(transcript: string, messageID: string): void {
    const data: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.ASR,
        transcript,
        messageID,
      },
    };
    this.ws.send(JSON.stringify(data));
  }

  /**
   * Informs the UI that a barge-in has been detected. A barge-in is when a user
   * interrupts the bot while it's speaking.
   */
  private sendUserBargeInToUser(): void {
    const data: BotChatMessage = {
      author: AuthorType.BOT,
      content: {
        type: ChatMessageContentType.USER_BARGE_IN,
      },
    };
    this.ws.send(JSON.stringify(data));
  }
}
