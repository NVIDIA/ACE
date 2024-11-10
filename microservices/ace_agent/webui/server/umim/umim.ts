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

export enum ActionModality {
  BOT_SPEECH = "bot_speech",
  BOT_POSTURE = "bot_posture",
  BOT_GESTURE = "bot_gesture",
  USER_SPEECH = "user_speech",
  BOT_FACE = "bot_face",
  BOT_UPPER_BODY = "bot_upper_body",
  BOT_LOWER_BODY = "bot_lower_body",
  USER_FACE = "user_face",
  USER_UPPER_BODY = "user_upper_body",
  USER_LOWER_BODY = "user_lower_body",
  USER_ENGAGEMENT = "user_engagement",
  SOUND = "sound",
  ENVIRONMENT = "environment",
  CAMERA = "camera",
  INFORMATION = "information",
  VISUAL_EFFECT = "visual_effect",
  USER_PRESENCE = "user_presence",
  BOT_ACTIVE_WAITING = "bot_active_waiting",
  BOT_EXPECTATION = "bot_expectation",
  CUSTOM = "custom",
  TIME = "time",
  WEB_REQUEST = "web_request",
}

export enum ActionModalityPolicy {
  PARALLEL = "parallel",
  OVERRIDE = "override",
  REPLACE = "replace",
  SKIP = "skip",
}

export abstract class UMIM_Event {
  readonly event_created_at: string = now();
  readonly uid: string = randomUUID();
  abstract readonly type: string;

  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = ({} = {})
  ) {}

  toJSONString(): string {
    try {
      return JSON.stringify(this);
    } catch (e) {
      console.error(
        "Failed to convert UMIM Event to JSON. Using empty string instead",
        e
      );
      return "";
    }
  }
}

export class UMIM_PipelineAcquired extends UMIM_Event {
  readonly type = "PipelineAcquired";
  constructor(
    readonly source_uid: string,
    readonly stream_uid: string,
    readonly user_uid?: string | null | undefined,
    readonly tags: { [id: string]: unknown } = {},
    readonly session_uid?: string | null | undefined
  ) {
    super(source_uid, tags);
  }
}

export class UMIM_PipelineReleased extends UMIM_Event {
  readonly type = "PipelineReleased";
  constructor(
    readonly source_uid: string,
    readonly stream_uid: string,
    readonly user_uid?: string | null | undefined,
    readonly tags: { [id: string]: unknown } = {},
    readonly session_uid?: string | null | undefined
  ) {
    super(source_uid, tags);
  }
}

export abstract class UMIM_ActionEvent extends UMIM_Event {
  abstract readonly action_info_modality: ActionModality;
  abstract readonly action_info_modality_policy: ActionModalityPolicy;

  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string
  ) {
    super(source_uid, tags);
  }
}

export abstract class UMIM_ActionFinished extends UMIM_ActionEvent {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined
  ) {
    super(source_uid, tags, action_uid);
  }
}

export abstract class UMIM_UserActionFinished extends UMIM_ActionFinished {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly user_uid?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped
    );
  }
}

export class UMIM_UtteranceUserActionFinished extends UMIM_UserActionFinished {
  readonly type = "UtteranceUserActionFinished";
  readonly action_info_modality = ActionModality.USER_SPEECH;
  readonly action_info_modality_policy = ActionModalityPolicy.REPLACE;

  constructor(
    readonly source_uid: string,
    readonly final_transcript: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly user_uid?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped,
      user_uid
    );
  }
}

abstract class UMIM_ActionStarted extends UMIM_ActionEvent {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_started_at: string = now()
  ) {
    super(source_uid, tags, action_uid);
  }
}

abstract class UMIM_UserActionStarted extends UMIM_ActionStarted {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_started_at: string = now(),
    readonly user_uid?: string | null | undefined
  ) {
    super(source_uid, tags, action_uid, action_started_at);
  }
}

export class UMIM_UtteranceUserActionStarted extends UMIM_UserActionStarted {
  readonly type = "UtteranceUserActionStarted";
  readonly action_info_modality = ActionModality.USER_SPEECH;
  readonly action_info_modality_policy = ActionModalityPolicy.REPLACE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_started_at: string = now(),
    readonly user_uid?: string | null | undefined
  ) {
    super(source_uid, tags, action_uid, action_started_at, user_uid);
  }
}

export abstract class UMIM_BotActionStarted extends UMIM_ActionStarted {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_started_at: string = now(),
    readonly bot_id?: string | undefined | null
  ) {
    super(source_uid, tags, action_uid, action_started_at);
  }
}

export abstract class UMIM_BotActionFinished extends UMIM_ActionFinished {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly bot_id?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped
    );
  }
}

export class UMIM_UtteranceBotActionFinished extends UMIM_BotActionFinished {
  readonly type = "UtteranceBotActionFinished";
  readonly action_info_modality = ActionModality.BOT_SPEECH;
  readonly action_info_modality_policy = ActionModalityPolicy.REPLACE;

  constructor(
    readonly source_uid: string,
    readonly final_script: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly bot_id?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped,
      bot_id
    );
  }
}

export class UMIM_UtteranceBotActionStarted extends UMIM_BotActionStarted {
  readonly type = "UtteranceBotActionStarted";
  readonly action_info_modality = ActionModality.BOT_SPEECH;
  readonly action_info_modality_policy = ActionModalityPolicy.REPLACE;
  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_started_at: string = now(),
    readonly bot_id?: string | undefined | null
  ) {
    super(source_uid, tags, action_uid, action_started_at, bot_id);
  }
}

export abstract class UMIM_ActionUpdated extends UMIM_ActionEvent {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_updated_at: string = now()
  ) {
    super(source_uid, tags, action_uid);
  }
}

export abstract class UMIM_UserActionExtended extends UMIM_ActionUpdated {
  constructor(
    readonly source_uid: string,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_uid: string = crypto.randomUUID(),
    readonly action_updated_at: string = now(),
    readonly user_id?: string | null | undefined
  ) {
    super(source_uid, tags, action_uid, action_updated_at);
  }
}

export class UMIM_UtteranceUserActionTranscriptUpdated extends UMIM_UserActionExtended {
  readonly type = "UtteranceUserActionTranscriptUpdated";
  readonly action_info_modality = ActionModality.USER_SPEECH;
  readonly action_info_modality_policy = ActionModalityPolicy.REPLACE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly interim_transcript: string,
    readonly stability: number = 0.1,
    readonly tags: { [id: string]: unknown } = {},
    readonly action_updated_at: string = now(),
    readonly user_id?: string | null | undefined
  ) {
    super(source_uid, tags, action_uid, action_updated_at, user_id);
  }
}

export class UMIM_TimerBotActionStarted extends UMIM_BotActionStarted {
  readonly type = "TimerBotActionStarted";
  readonly action_info_modality = ActionModality.TIME;
  readonly action_info_modality_policy = ActionModalityPolicy.PARALLEL;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_started_at: string = now(),
    readonly bot_id?: string | undefined | null
  ) {
    super(source_uid, tags, action_uid, action_started_at, bot_id);
  }
}

export class UMIM_TimerBotActionFinished extends UMIM_BotActionFinished {
  readonly type = "TimerBotActionFinished";
  readonly action_info_modality = ActionModality.TIME;
  readonly action_info_modality_policy = ActionModalityPolicy.PARALLEL;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly bot_id?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped,
      bot_id
    );
  }
}

export class UMIM_PostureBotActionStarted extends UMIM_BotActionStarted {
  readonly type = "PostureBotActionStarted";
  readonly action_info_modality = ActionModality.BOT_POSTURE;
  readonly action_info_modality_policy = ActionModalityPolicy.OVERRIDE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_started_at: string = now(),
    readonly bot_id?: string | undefined | null
  ) {
    super(source_uid, tags, action_uid, action_started_at, bot_id);
  }
}

export class UMIM_PostureBotActionFinished extends UMIM_BotActionFinished {
  readonly type = "PostureBotActionFinished";
  readonly action_info_modality = ActionModality.BOT_POSTURE;
  readonly action_info_modality_policy = ActionModalityPolicy.OVERRIDE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly bot_id?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped,
      bot_id
    );
  }
}

export class UMIM_GestureBotActionStarted extends UMIM_BotActionStarted {
  readonly type = "GestureBotActionStarted";
  readonly action_info_modality = ActionModality.BOT_GESTURE;
  readonly action_info_modality_policy = ActionModalityPolicy.OVERRIDE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_started_at: string = now(),
    readonly bot_id?: string | undefined | null
  ) {
    super(source_uid, tags, action_uid, action_started_at, bot_id);
  }
}

export class UMIM_GestureBotActionFinished extends UMIM_BotActionFinished {
  readonly type = "GestureBotActionFinished";
  readonly action_info_modality = ActionModality.BOT_GESTURE;
  readonly action_info_modality_policy = ActionModalityPolicy.OVERRIDE;

  constructor(
    readonly source_uid: string,
    readonly action_uid: string = crypto.randomUUID(),
    readonly tags: { [id: string]: unknown } = {},
    readonly action_finished_at: string = now(),
    readonly is_success: boolean = true,
    readonly failure_reason?: string | null | undefined,
    readonly was_stopped?: boolean | null | undefined,
    readonly bot_id?: string | null | undefined
  ) {
    super(
      source_uid,
      tags,
      action_uid,
      action_finished_at,
      is_success,
      failure_reason,
      was_stopped,
      bot_id
    );
  }
}

function now(): string {
  return new Date().toISOString();
}
