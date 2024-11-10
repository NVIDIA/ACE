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

export const REDIS_URL = process.env.REDIS_URL ?? "redis://localhost:6379";
export const SERVER_PORT = parseInt(process.env.VITE_SERVER_PORT) || 7007;
export const EMOJI_FILE_PATH =
  process.env.EMOJI_FILE_PATH ?? "./data/emojis-all.json";
export const UMIM_SOURCE_NAME =
  process.env.UMIM_SOURCE_NAME ?? "ace-agent-bot-ui";
export const SYSTEM_EVENTS_STREAM =
  process.env.SYSTEM_EVENTS_STREAM ?? "ace_agent_system_events";
export const GRPC_URL = process.env.GRPC_URL ?? "http://localhost:50055";
export const HTTP_CHAT_URL =
  process.env.HTTP_CHAT_URL ?? "http://localhost:9000";

export const USER_SPEECH_SAMPLE_RATE =
  parseInt(process.env.USER_SPEECH_SAMPLE_RATE) || 16000;
