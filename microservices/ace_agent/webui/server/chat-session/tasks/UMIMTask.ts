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

import { createClient } from "redis";
import AbstractTask from "./AbstractTask.js";
import {
  UMIM_GestureBotActionFinished,
  UMIM_GestureBotActionStarted,
  UMIM_PipelineAcquired,
  UMIM_PipelineReleased,
  UMIM_PostureBotActionFinished,
  UMIM_PostureBotActionStarted,
  UMIM_TimerBotActionFinished,
  UMIM_TimerBotActionStarted,
  UMIM_UtteranceBotActionFinished,
  UMIM_UtteranceBotActionStarted,
  UMIM_UtteranceUserActionFinished,
  UMIM_UtteranceUserActionStarted,
  UMIM_UtteranceUserActionTranscriptUpdated,
} from "../../umim/umim.js";
import { EventEmitter, once } from "node:events";
import getLogger from "../logger.js";
import RedisClient from "../clients/RedisClient.js";
import { InteractionMode } from "../../../shared/types.js";
import { SYSTEM_EVENTS_STREAM, UMIM_SOURCE_NAME } from "../../config.js";
import sleep from "../../utils/sleep.js";

const logger = getLogger("UMIMTask");

/**
 * This task handles the UMIM session through Redis. It's responsible for handling
 * incoming UMIM events, and send back relevant UMIM events.
 *
 * It continuously listens for new UMIM events coming through the specified Redis
 * stream. When receiving a new event, the task may handle it directly. For example, when
 * receving a `StartTimerBotAction`, it responds with a TimerBotActionFinished event
 * after the specified duration.
 *
 * When receving events that should be handled by other tasks (e.g. the bot sent an
 * utterance that must be sent to the user), it dispatches a message through the shared
 * event bus.
 *
 * The task also subscribes to events emitted by other tasks. For example, when another
 * task emits the `userStartedNewMessage` event, this task sends a
 * `UtteranceUserActionStarted` event through Redis.
 */
export default class UMIMTask extends AbstractTask {
  public readonly interactionModes: InteractionMode[] = [
    InteractionMode.SPEECH,
    InteractionMode.TEXT,
  ];

  // The Redis channel for the stream. Automatically inferred from the streamID.
  private readonly channelKey: string;

  // The ID for the last message received through the Redis channel. This is needed to
  // keep listening for new messages.
  private lastRedisMessageID: string = "0";

  private pipelineAcquired: boolean = false;

  private currentInteractionMode: InteractionMode = InteractionMode.TEXT;

  constructor(eventBus: EventEmitter, private readonly streamID: string) {
    super(eventBus);
    this.channelKey = `umim_events_${this.streamID}`;
  }

  public override async cleanup(): Promise<void> {
    if (this.pipelineAcquired) {
      await this.informUMIMPipelineReleased();
    }
  }

  /**
   * Starts all the listeners
   */
  public override async start(): Promise<void> {
    super.start();

    logger.info("starting running task");
    try {
      if (!this.pipelineAcquired) {
        logger.info("Acquiring UMIM pipeline");
        this.pipelineAcquired = true;
        await this.informUMIMPipelineAcquired();
      }
      await Promise.all([
        this.listenRedisBotMessages(),
        this.listenRedisErrors(),
        this.listenUserStartedNewMessage(),
        this.listenUserUpdatedMessage(),
        this.listenUserFinishedMessage(),
        this.listenUserToggledSpeech(),
      ]);
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
   * The task continuously listens to new messages through the Redis stream, until the
   * stop() method is called. New messages are processed through handleRedisEvent().
   */
  private async listenRedisBotMessages(): Promise<void> {
    logger.info("awaiting for new messages on channel %s", this.channelKey);
    const redisClient = await RedisClient.get();
    while (this.isRunning()) {
      const responses = await redisClient.xRead(
        { key: this.channelKey, id: this.lastRedisMessageID },
        { COUNT: 20, BLOCK: 1000 }
      );
      if (responses) {
        for (const response of responses) {
          for (const event of response.messages) {
            this.handleRedisEvent(event.message.event);
            this.lastRedisMessageID = event?.id ?? this.lastRedisMessageID;
          }
        }
      }
    }
  }

  /**
   * Continuously listens for the user starting to type a new message.
   */
  private async listenUserStartedNewMessage(): Promise<void> {
    while (this.isRunning()) {
      const [messageID] = await once(
        this.eventBus,
        "userStartedNewMessage",
        this.abortController
      );
      this.handleUserStartedNewMessage(messageID);
    }
  }

  /**
   * Continuously listens for the user updating their messages (in other words, this is
   * called every time the user types a letter).
   */
  private async listenUserUpdatedMessage(): Promise<void> {
    while (this.isRunning()) {
      const [messageID, text] = await once(
        this.eventBus,
        "userUpdatedMessage",
        this.abortController
      );
      this.handleUserUpdatedMessage(messageID, text);
    }
  }

  /**
   * Continuously listens for the user submitting full messages (in other words, when
   * the user submtis the message).
   */
  private async listenUserFinishedMessage(): Promise<void> {
    while (this.isRunning()) {
      const [messageID, text] = await once(
        this.eventBus,
        "userFinishedMessage",
        this.abortController
      );
      this.handleUserFinishedMessage(messageID, text);
    }
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
   * Continuously listens for errors on the Redis client.
   */
  private async listenRedisErrors(): Promise<void> {
    const redisClient = await RedisClient.get();
    while (this.isRunning()) {
      const [error] = await once(redisClient, "error", this.abortController);
      this.handleRedisError(error);
    }
  }

  /**
   * Handles an incoming Redis event. The event is parsed, and the appropriate action
   * is taken based on the event's type.
   * @param event the Redis event content, as JSON string
   */
  private async handleRedisEvent(event: string): Promise<void> {
    let parsed;
    try {
      parsed = JSON.parse(event);
    } catch (e) {
      logger.error(
        "Could not parse redis message as JSON. Ignoring message",
        event
      );
      return;
    }

    if (parsed.source_uid === UMIM_SOURCE_NAME) {
      logger.info(
        `Ignoring ${parsed.type} because it was sent by us (the UI server), not the bot`
      );
      return;
    }
    switch (parsed.type) {
      case "StartTimerBotAction": {
        this.handleStartTimerBotAction(
          parsed.action_uid,
          parsed.duration,
          new Date(parsed.event_created_at)
        );
        break;
      }
      case "StopTimerBotAction": {
        this.handleStopTimerBotAction(parsed.action_uid);
        break;
      }
      case "StartPostureBotAction": {
        this.handlePostureBotAction(parsed.action_uid, parsed.posture);
        break;
      }
      case "StopPostureBotAction": {
        this.handleStopPostureBotAction(parsed.action_uid);
        break;
      }
      case "StartGestureBotAction": {
        this.handleStartGestureBotAction(
          parsed.action_uid,
          parsed.gesture,
          parsed.source_uid
        );
        break;
      }
      case "StartUtteranceBotAction": {
        this.handleStartUtteranceBotAction(
          parsed.action_uid,
          parsed.script,
          parsed.source_uid
        );
        break;
      }
      case "UtteranceUserActionTranscriptUpdated": {
        this.handleUtteranceUserActionTranscriptUpdated(
          parsed.action_uid,
          parsed.interim_transcript,
          parsed.source_uid
        );
        break;
      }
      case "UtteranceUserActionFinished": {
        this.handleUtteranceUserActionFinished(
          parsed.action_uid,
          parsed.final_transcript,
          parsed.source_uid
        );
        break;
      }
      case "StopUtteranceBotAction": {
        this.handleStopUtteranceBotAction();
        break;
      }
    }
  }

  /**
   * Handles a new message sent by the user. Sends a `UtteranceUserActionStarted`
   * event to the bot.
   * @param messageID the ID for the message
   */
  private async handleUserStartedNewMessage(messageID: string): Promise<void> {
    const redisClient = await RedisClient.get();
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_UtteranceUserActionStarted(
        UMIM_SOURCE_NAME,
        messageID
      ).toJSONString(),
    });
  }

  /**
   * Handles a message that was updated by the user (typically, every time the user
   * types a key on the user interface). Sends a UtteranceUserActionTranscriptUpdated
   * to the bot, containing the updated text for the message.
   * @param messageID the ID of the message
   * @param text the text of the message
   */
  private async handleUserUpdatedMessage(
    messageID: string,
    text: string
  ): Promise<void> {
    const redisClient = await RedisClient.get();
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_UtteranceUserActionTranscriptUpdated(
        UMIM_SOURCE_NAME,
        messageID,
        text
      ).toJSONString(),
    });
  }

  /**
   * Handles a message that was completed by the user (typically, when the user submits
   * the messages on the user interface). Sends the final text for the message to the bot
   * through a UtteranceUserActionFinished event.
   * @param messageID the ID of the message
   * @param text the final text content of the message
   */
  private async handleUserFinishedMessage(
    messageID: string,
    text: string
  ): Promise<void> {
    const redisClient = await RedisClient.get();
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_UtteranceUserActionFinished(
        UMIM_SOURCE_NAME,
        text,
        messageID
      ).toJSONString(),
    });
  }

  /**
   * Handles an incoming StartTimerBotAction event. This immediately sends back a
   * `TimerBotActionStarted` event. Then, after the specified duration has elapsed, sends
   * a `TimerBotActionFinished`.
   * @param actionUID the ID for the action
   * @param durationSec the duration of the timer
   */
  private async handleStartTimerBotAction(
    actionUID: string,
    durationSec: number,
    eventCreatedAt: Date
  ): Promise<void> {
    const redisClient = await RedisClient.get();

    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_TimerBotActionStarted(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });

    const now = new Date();
    const finishedTime = new Date(
      eventCreatedAt.getTime() + durationSec * 1000
    );
    const duration = finishedTime.getTime() - now.getTime();

    await sleep(duration);

    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_TimerBotActionFinished(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles an incoming StopTimerBotAction. This immediately sends back a
   * `TimerBotActionFinished` event to the bot.
   * @param actionUID
   */
  private async handleStopTimerBotAction(actionUID: string): Promise<void> {
    const redisClient = await RedisClient.get();
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_TimerBotActionFinished(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles a "PostureBotAction" event received from the bot. This immediately sends back
   * a PostureBotActionStarted event. If the posture is "Thinking, idle" (which is
   * typically sent as the bot is preparing a response to a user message), a
   * "botStartedThinkingIdle" event is emitted on the shared eventBus. This allows
   * to show a "thinking" state on the UI.
   * @param actionUID the ID for the action
   * @param posture the posture for the bot
   */
  private async handlePostureBotAction(
    actionUID: string,
    posture: string
  ): Promise<void> {
    const redisClient = await RedisClient.get();
    if (posture === "Thinking, idle") {
      this.eventBus.emit("botStartedThinkingIdle", actionUID);
    }
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_PostureBotActionStarted(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles a `StopPostureBotAction` from the bot. This immediately sends back a
   * "PostBotActionFinished" event.
   * @param actionUID the ID for the action
   */
  private async handleStopPostureBotAction(actionUID: string): Promise<void> {
    const redisClient = await RedisClient.get();
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_PostureBotActionFinished(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles a StartGestureBotAction from the bot. This immediately sends back a
   * `GestureBotActionStarted` and `GestureBotActionFinished` events. Additionally,
   * this emits a botStartedGesture on the shared eventBus, so that other task
   * can handle the event.
   * @param actionUID
   * @param gesture
   */
  private async handleStartGestureBotAction(
    actionUID: string,
    gesture: string,
    botName: string
  ): Promise<void> {
    const redisClient = await RedisClient.get();
    this.eventBus.emit("botStartedGesture", actionUID, gesture, botName);
    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_GestureBotActionStarted(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });

    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_GestureBotActionFinished(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles an incoming StartUtteranceBotAction. When the user is using text mode, this
   * immediately sends back `UtteranceBotActionStarted` and `UtteranceBotActionFinished`
   * events, and emits a `botStartedUtterance` event on the shared eventBus, for other
   * tasks to handle.
   *
   * In speech mode, this only sends the bot's speech in text form so that we can show
   * it in the UI. It does not send back UtteranceBotActionStarted or
   * UtteranceBotActionFinished events, which are handled by ACE Agent.
   *
   * @param actionUID the ID for the action
   * @param text the text that the bot speaks
   */
  private async handleStartUtteranceBotAction(
    actionUID: string,
    text: string,
    botName: string
  ): Promise<void> {
    const redisClient = await RedisClient.get();
    this.eventBus.emit("botStartedUtterance", actionUID, text, botName);

    if (this.currentInteractionMode === InteractionMode.SPEECH) {
      logger.info(
        "Ignoring StartUtteranceBotAction because the UI is in speech mode. In this mode, UtteranceBotActionStarted and UtteranceBotActionFinished are handled by ACE Agent"
      );
      return;
    }

    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_UtteranceBotActionStarted(
        UMIM_SOURCE_NAME,
        actionUID
      ).toJSONString(),
    });

    await redisClient.xAdd(this.channelKey, "*", {
      event: new UMIM_UtteranceBotActionFinished(
        UMIM_SOURCE_NAME,
        text,
        actionUID
      ).toJSONString(),
    });
  }

  /**
   * Handles user's ASR transcript being updated
   */
  private handleUtteranceUserActionTranscriptUpdated(
    actionUID: string,
    transcript: string,
    sourceID: string
  ): void {
    this.eventBus.emit("asrAvailable", transcript, actionUID);
  }

  private handleUtteranceUserActionFinished(
    actionUID: string,
    transcript: string,
    sourceID: string
  ): void {
    if (!transcript) {
      logger.warn(
        "Received empty transcript from UtteranceUserActionFinished. Ignoring"
      );
      return;
    }
    this.eventBus.emit("asrAvailable", transcript, actionUID);
  }
  /*
   * Handles an incoming StopUtteranceBotAction. This happens when the bot stops speaking
   * because the user has interrupted it, also known as a "barge in"
   */
  private handleStopUtteranceBotAction() {
    this.eventBus.emit("userBargeIn");
  }

  /**
   * Handles errors sent by the redis client. In practice, this function just logs the
   * error without interrupting the task.
   * @param e
   */
  private handleRedisError(e: Error) {
    logger.error("received error from Redis client", e);
  }

  /**
   * Called when the user toggles speech mode. When the user enables speech mode, the UMIM
   * Task stops acting as an UMIM action server. This means it will no longer send events
   * like "UtteranceBotActionFinished". This responsibility is assumed by ACE Agent
   * @param interactionMode the user's desired interaction mode (text or speech)
   */
  private async handleUserToggledSpeech(
    interactionMode: InteractionMode
  ): Promise<void> {
    if (interactionMode === InteractionMode.SPEECH) {
      logger.info(
        "User toggled interaction mode to speech. UMIMTask will stop acting as an action server"
      );
    } else {
      logger.info(
        "User toggled interaction mode to text. UMIMTask will act as an action server again",
        interactionMode
      );
    }
    this.currentInteractionMode = interactionMode;
  }

  /**
   * Informs the UMIM bot that a user has started a chat session.
   */
  private async informUMIMPipelineAcquired(): Promise<void> {
    const redisClient = await RedisClient.get();
    logger.info("Informing UMIM Pipeline acquired, streamID=%s", this.streamID);
    await redisClient.xAdd(SYSTEM_EVENTS_STREAM, "*", {
      event: new UMIM_PipelineAcquired(
        UMIM_SOURCE_NAME,
        this.streamID,
        this.streamID
      ).toJSONString(),
    });
  }

  /**
   * Informs the UMIM bot that a user has left the chat session. This should be called
   * when the task is cleaned up.
   */
  private async informUMIMPipelineReleased(): Promise<void> {
    const redisClient = await RedisClient.get();
    logger.info("Informing UMIM Pipeline released, streamID=%s", this.streamID);
    await redisClient.xAdd(SYSTEM_EVENTS_STREAM, "*", {
      event: new UMIM_PipelineReleased(
        UMIM_SOURCE_NAME,
        this.streamID,
        this.streamID
      ).toJSONString(),
    });
  }
}
