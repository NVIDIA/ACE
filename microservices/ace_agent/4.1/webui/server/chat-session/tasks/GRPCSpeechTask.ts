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
import {
  AudioEncoding,
  ReceiveAudioRequest,
  SendAudioRequest,
  StreamingRecognitionConfig,
} from "../../grpc/gen/ace_agent_pb.js";
import sleep from "../../utils/sleep.js";
import { InteractionMode } from "../../../shared/types.js";

import GRPCClient from "../clients/GRPCClient.js";
import { USER_SPEECH_SAMPLE_RATE } from "../../config.js";

const logger = getLogger("GRPCSpeechTask");

/**
 * This task is responsible for handling speech-related aspects of the app:
 * - When the user sends audio chunks, this task enqueues them, and sends them to ACE
 *   Agent through its sendAudio API.
 * - When ACE Agent sends the bot's audio chunk, this task emits them on the shared event
 *   bus, so that other tasks can handle them.
 */
export default class GRPCSpeechTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [
    InteractionMode.SPEECH,
  ];

  private readonly gRPCClient = GRPCClient.get();

  /**
   * The list of audio chunks that have not been sent to ACE Agent yet.
   */
  private readonly userAudioChunks: ArrayBuffer[] = [];

  /**
   * Whether the pipeline was acquired by this task before. This is to ensure the task
   * doesn't needlessly re-acquire the pipeline every time it is re-started (in other
   * words: whenever the user switch between interaction modes from the UI).
   */
  private pipelineAcquired: boolean = false;

  constructor(
    protected readonly eventBus: EventEmitter,
    private readonly streamID: string
  ) {
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

      await Promise.all([
        this.listenBotAudio(),
        this.listenUserSentAudio(),
        this.processUserAudioQueue(),
      ]);
    } catch (e) {
      if (e.code === "ABORT_ERR") {
        // The task was stopped while it was listening for events on the eventBus. This
        // is OK
        return;
      }
      logger.fatal("Caught error while running task", e);
      this.eventBus.emit("fatalError", this.constructor.name, e);
    }
  }

  /**
   * Listens to ACE Agent's  `receiveAudio` gRPC call. When a new chunk is it's
   * immediately sent through a `botSentAudio` message on the shared event bus for other
   * tasks to handle.
   */
  private async listenBotAudio(): Promise<void> {
    logger.info("Starting to listen for bot audio");
    while (this.isRunning()) {
      const request = new ReceiveAudioRequest({
        streamId: this.streamID,
      });
      const audioResponse = this.gRPCClient.receiveAudio(request, {
        signal: this.abortController.signal,
      });

      for await (const chunk of audioResponse) {
        logger.info(
          "Received audio chunk from bot. Sample rate=%s",
          chunk.sampleRateHertz
        );
        this.eventBus.emit("botSentAudio", chunk.audioContent);
      }
    }
  }

  /**
   * Continuously listens for the user sending audio chunks.
   */
  private async listenUserSentAudio(): Promise<void> {
    while (this.isRunning()) {
      const [chunk] = await once(
        this.eventBus,
        "userSentAudio",
        this.abortController
      );
      this.handleUserSentAudio(chunk);
    }
  }

  /**
   * When a new audio chunk is available, the chunk is added to an internal queue. The
   * queue is processed asynchronously (see processUserAudioQueue()).
   * @param chunk the new audio chunk
   */
  private handleUserSentAudio(chunk: ArrayBuffer): void {
    logger.info("Enqueuing user audio chunk for processing");
    this.userAudioChunks.push(chunk);
  }

  /**
   * The main logic of this task is to continuously inspect the internal queue of audio
   * chunks from the user. When one or more audio chunks are available, they are
   * sent to ACE Agent through the client-side streaming `sendAudio` gRPC call.
   */
  private async processUserAudioQueue(): Promise<void> {
    logger.info("Starting to listen for new audio chunks");

    const task = this;
    async function* audioChunkGenerator() {
      yield new SendAudioRequest({
        streamId: task.streamID,
        streamingRequest: {
          case: "streamingConfig",
          value: new StreamingRecognitionConfig({
            audioChannelCount: 1,
            encoding: AudioEncoding.LINEAR_PCM,
            sampleRateHertz: USER_SPEECH_SAMPLE_RATE,
          }),
        },
      });
      while (task.isRunning()) {
        if (task.userAudioChunks.length > 0) {
          logger.info("Sending user audio chunk to ACE Agent through gRPC");
          yield new SendAudioRequest({
            streamingRequest: {
              case: "audioContent",
              value: new Uint8Array(task.userAudioChunks.shift()),
            },
          });
        } else {
          await task.nextTick();
        }
      }
    }

    const audioChunksIterator = audioChunkGenerator();
    await this.gRPCClient.sendAudio(audioChunksIterator, {
      signal: this.abortController.signal,
    });
  }

  /**
   * Informs ACE Agent that the user has started a chat session.
   */
  private async informGRPCPipelineAcquired(): Promise<void> {
    await this.gRPCClient.createPipeline({
      streamId: this.streamID,
      userId: this.streamID,
    });
  }

  /**
   * Informs ACE Agent that the user has started a chat session. This should be called
   * when the task is cleaned up.
   */
  private async informGRPCPipelineReleased(): Promise<void> {
    await this.gRPCClient.freePipeline({
      streamId: this.streamID,
      userId: this.streamID,
    });
  }

  /**
   * A utility function to pause execution. This allows other tasks to run while the
   * current task waits for audio chunks.
   */
  private async nextTick(): Promise<void> {
    await sleep(1);
  }
}
