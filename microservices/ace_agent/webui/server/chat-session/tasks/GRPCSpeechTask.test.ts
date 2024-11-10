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
import GRPCSpeechTask from "./GRPCSpeechTask";
import { AceAgentGrpc } from "../../grpc/gen/ace_agent_connect";
import { PromiseClient } from "@connectrpc/connect";
import { EventEmitter } from "node:events";
import sleep from "../../utils/sleep";
import * as assert from "node:assert";
import { APIStatus } from "../../grpc/gen/ace_agent_pb.js";
import GRPCClient from "../clients/GRPCClient";
import waitAbortSignal from "../../utils/waitAbortSignal";

type GRPCClient = PromiseClient<typeof AceAgentGrpc>;

const mockSendAudio = mock.fn(
  () => {},
  () => ({ status: APIStatus.SUCCESS })
);

const mockReceiveAudio = mock.fn(
  () => {},
  (_request, abortSignal) => {
    return [waitAbortSignal(abortSignal)];
  }
);

const mockStreamSpeechResults = mock.fn(
  () => {},
  (_request, abortSignal) => {
    return [waitAbortSignal(abortSignal)];
  }
);

mock.method(GRPCClient, "get").mock.mockImplementation(() => {
  return {
    sendAudio: mockSendAudio,
    receiveAudio: mockReceiveAudio,
    streamSpeechResults: mockStreamSpeechResults,
    createPipeline: mock.fn(),
    freePipeline: mock.fn(),
  };
});

describe("GRPCSpeechTask", () => {
  let task: GRPCSpeechTask;
  let eventBus = new EventEmitter();
  before(() => {
    task = new GRPCSpeechTask(eventBus, "test_stream_id");
    task.start();
  });

  after(() => {
    task.stop();
  });

  beforeEach(() => {
    mockSendAudio.mock.resetCalls();
  });

  /**
   * Utility function to emulate the user sending audio
   */
  async function sendUserAudio(): Promise<void> {
    const chunk = new ArrayBuffer(10); // empty buffer for testing
    eventBus.emit("userSentAudio", chunk);
    await sleep(1);
  }

  it("Sends audio to the bot when the user sent a new chunk", async () => {
    await sendUserAudio();

    assert.strictEqual(mockSendAudio.mock.callCount(), 1);
  });
});
