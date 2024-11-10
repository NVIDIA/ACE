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
import { PromiseClient } from "@connectrpc/connect";
import { AceAgentGrpc } from "../../grpc/gen/ace_agent_connect";
import { EventEmitter } from "node:events";
import getLogger from "../logger.js";
import { StreamingSpeechResultsRequest } from "../../grpc/gen/ace_agent_pb.js";
import { randomUUID } from "node:crypto";
import { InteractionMode } from "../../../shared/types.js";
import GRPCClient from "../clients/GRPCClient.js";

type GRPCClient = PromiseClient<typeof AceAgentGrpc>;
const logger = getLogger("GRPCSpeechTranscriptionTask");

/**
 * This task is responsible for managing speech transcriptions. It listens from
 * the gRPC client's StreamingSpeechResultsRequest and, when receiving a speech
 * transcript, emits it on the shared event bus for other tasks to handle.
 *
 * This task is only used when ACE Agent is not running in "event" mode. In event
 * mode, speech transcriptions are handled by the UMIMTask.
 */
export default class GRPCSpeechTranscriptionTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [
    InteractionMode.SPEECH,
  ];

  private readonly gRPCClient = GRPCClient.get();

  // Each utterance must have a unique message ID. An utterance typically receives
  // many ASR updates, as the engine hears more words from the user. Each ASR update
  // belonging to the same utterance must have the same message ID. This allows the
  // UI to show the current utterance being built in real time in a speech bubble. Once
  // the utterance is completed, the message ID is incremented, allowing the UI to
  // create a new speech bubble.
  private currentMessageID: number = 0;

  constructor(eventBus: EventEmitter, private readonly streamID: string) {
    super(eventBus);
  }

  public override async start(): Promise<void> {
    super.start();
    try {
      await this.listenTextTranscription();
    } catch (e) {
      if (e.code === 1) {
        // The task was stopped while a gRPC call was in progress. This is OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Listens for text transcriptions through the gRPC client. When a new transcript
   * is available, sends it through the shared event bus.
   */
  public async listenTextTranscription(): Promise<void> {
    logger.info("Starting to listen for metadata");
    while (this.isRunning()) {
      const request = new StreamingSpeechResultsRequest({
        streamId: this.streamID,
        requestId: "GRPCSpeechTranscriptionTask",
      });
      const metaDataResponse = this.gRPCClient.streamSpeechResults(request, {
        signal: this.abortController.signal,
      });

      for await (const response of metaDataResponse) {
        logger.info("received metadata", response.metadata.case);
        switch (response.metadata.case) {
          case "displayText":
            const text = response.metadata.value;
            this.eventBus.emit("botStartedUtterance", randomUUID(), text, null);
            break;
          case "asrResult":
            const asr = response.metadata.value.results;
            this.eventBus.emit(
              "asrAvailable",
              asr.alternatives[0].transcript,
              this.currentMessageID
            );
            if (asr.isFinal) {
              this.currentMessageID++;
            }
        }
      }
    }
  }
}
