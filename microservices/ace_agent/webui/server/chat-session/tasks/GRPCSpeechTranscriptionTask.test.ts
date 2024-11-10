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

import { after, before, beforeEach, describe, it, mock } from "node:test";
import { AceAgentGrpc } from "../../grpc/gen/ace_agent_connect";
import { PromiseClient } from "@connectrpc/connect";
import { EventEmitter } from "node:events";
import sleep from "../../utils/sleep";
import * as assert from "node:assert";
import GRPCClient from "../clients/GRPCClient";
import GRPCSpeechTranscriptionTask from "./GRPCSpeechTranscriptionTask";
import waitAbortSignal from "../../utils/waitAbortSignal";

type GRPCClient = PromiseClient<typeof AceAgentGrpc>;

mock.method(GRPCClient, "get").mock.mockImplementation(() => {
  return {
    streamSpeechResults: mock.fn(
      () => {},
      (_req, abortSignal) => [
        { metadata: { case: "displayText", value: "I am a bot!" } },
        waitAbortSignal(abortSignal),
      ]
    ),
  };
});

describe("GRPCSpeechTranscriptionTask", () => {
  it("Emits a botStartedUtterance event on the shared event bus when the bot streams a speech transcription", async () => {
    const eventBus = new EventEmitter();
    const spy = mock.fn();
    eventBus.addListener("botStartedUtterance", spy);
    const task = new GRPCSpeechTranscriptionTask(eventBus, "test_stream_id");
    task.start();
    await sleep(1);
    task.stop();
    assert.strictEqual(spy.mock.callCount(), 1);
    assert.strictEqual(spy.mock.calls[0].arguments[1], "I am a bot!");
  });
});
