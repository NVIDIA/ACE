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

import { describe, it, before, after, mock, beforeEach } from "node:test";
import * as assert from "node:assert";
import WebSocketTask from "./WebSocketTask";
import { EventEmitter } from "node:stream";
import EmojiFinder from "../../emoji-finder";
import type { WebSocket } from "ws";
import {
  AuthorType,
  ChatMessageContentType,
  UserChatMessage,
} from "../../../shared/types";
import sleep from "../../utils/sleep";

const mockWebSocket = new EventEmitter() as WebSocket;
mockWebSocket.send = mock.fn();

describe("WebSocketTask", () => {
  let task: WebSocketTask;
  let emojiFinder: EmojiFinder;
  let eventBus: EventEmitter;
  before(async () => {
    eventBus = new EventEmitter();
    emojiFinder = new EmojiFinder([
      {
        emoji: "🕺",
        description: "man dancing",
        aliases: ["man_dancing"],
        tags: ["dancer"],
      },
    ]);
    await emojiFinder.init();
    task = new WebSocketTask(eventBus, emojiFinder, mockWebSocket);
    task.start();
  });

  beforeEach(() => {
    (mockWebSocket.send as any).mock.resetCalls();
  });

  after(() => {
    task.stop();
  });

  /**
   * Utility to emulate a user typing a message
   */
  async function sendUserTyping(
    isNewMessage: boolean = true,
    text: string = null
  ) {
    const message: UserChatMessage = {
      author: AuthorType.USER,
      content: {
        type: ChatMessageContentType.TYPING,
        messageID: "test_message_id",
        text,
        isNewMessage,
      },
    };
    mockWebSocket.emit("message", JSON.stringify(message));
    await sleep(1); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate a user submitting a message
   */
  async function sendUserMessage(text: string) {
    const message: UserChatMessage = {
      author: AuthorType.USER,
      content: {
        type: ChatMessageContentType.TEXT,
        messageID: "test_message_id",
        text,
        botName: "test_bot_v1",
      },
    };
    mockWebSocket.emit("message", JSON.stringify(message));
    await sleep(1); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate the bot sending an utterance
   */
  async function sendBotUtterance(text: string) {
    eventBus.emit("botStartedUtterance", "test_action_id", text, "test_bot_v1");
    await sleep(100); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate the bot sending a signal that it is thinking
   */
  async function sendBotThinking() {
    eventBus.emit("botStartedThinkingIdle");
    await sleep(100); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate the bot sending a gesture
   */
  async function sendBotGesture(text: string) {
    eventBus.emit("botStartedGesture", "test_action_id", text);
    await sleep(100); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate the bot sending audio
   */
  async function sendBotAudio() {
    const audio = new Uint8Array(10); // empty chunk for testing
    eventBus.emit("botSentAudio", audio);
    await sleep(100); // to give time to the loop to read the message
  }

  /**
   * Utility to emulate the bot sending ASR data to the user
   */
  async function sendASR(text: string) {
    eventBus.emit("asrAvailable", text);
    await sleep(100); // to give time to the loop to read the message
  }

  it('Emits a "userStartedNewMessage" event when the user started typing', async () => {
    const callback = mock.fn();
    eventBus.on("userStartedNewMessage", callback);
    await sendUserTyping();
    assert.strictEqual(callback.mock.callCount(), 1);
    assert.strictEqual(callback.mock.calls[0].arguments[0], "test_message_id");
  });

  it('Emits a "userUpdatedMessage" event when the user updates their message', async () => {
    const callback = mock.fn();
    eventBus.on("userUpdatedMessage", callback);
    await sendUserTyping(false, "I am typing!");
    assert.strictEqual(callback.mock.callCount(), 1);
    assert.strictEqual(callback.mock.calls[0].arguments[0], "test_message_id");
    assert.strictEqual(callback.mock.calls[0].arguments[1], "I am typing!");
  });

  it('Emits a "userFinishedMessage" event when the user submits their message', async () => {
    const callback = mock.fn();
    eventBus.on("userFinishedMessage", callback);
    await sendUserMessage("Hello, world!");
    assert.strictEqual(callback.mock.callCount(), 1);
    assert.strictEqual(callback.mock.calls[0].arguments[0], "test_message_id");
    assert.strictEqual(callback.mock.calls[0].arguments[1], "Hello, world!");
  });

  it("Sends a message to the user when the bot sends an utterance", async () => {
    await sendBotUtterance("I am a bot!");
    assert.strictEqual((mockWebSocket.send as any).mock.callCount(), 1);
    const message = JSON.parse(
      (mockWebSocket.send as any).mock.calls[0].arguments[0]
    );
    assert.strictEqual(message.content.text, "I am a bot!");
  });

  it("Sends a 'typing' event to the user when the bot starts thinking", async () => {
    await sendBotThinking();
    assert.strictEqual((mockWebSocket.send as any).mock.callCount(), 1);
    const message = JSON.parse(
      (mockWebSocket.send as any).mock.calls[0].arguments[0]
    );
    assert.strictEqual(message.content.type, ChatMessageContentType.TYPING);
  });

  it("Sends an emoji to the user when the bot sends a gesture", async () => {
    await sendBotGesture("Dancing");
    assert.strictEqual((mockWebSocket.send as any).mock.callCount(), 1);
    const message = JSON.parse(
      (mockWebSocket.send as any).mock.calls[0].arguments[0]
    );
    assert.strictEqual(message.content.type, ChatMessageContentType.EMOJI);
    assert.strictEqual(message.content.emoji, "🕺");
  });

  it("Sends audio to the user when the bot sends an audio chunk", async () => {
    await sendBotAudio();
    assert.strictEqual((mockWebSocket.send as any).mock.callCount(), 1);
    const message = (mockWebSocket.send as any).mock.calls[0].arguments[0];
    assert.ok(message instanceof Uint8Array);
  });

  it("Sends ASR data to the user when the bot sends ASR", async () => {
    await sendASR("How are you doing?");
    assert.strictEqual((mockWebSocket.send as any).mock.callCount(), 1);
    const message = JSON.parse(
      (mockWebSocket.send as any).mock.calls[0].arguments[0]
    );
    assert.strictEqual(message.content.type, ChatMessageContentType.ASR);
    assert.strictEqual(message.content.transcript, "How are you doing?");
  });
});
