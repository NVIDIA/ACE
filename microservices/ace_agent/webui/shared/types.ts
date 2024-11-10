
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

export type MessageID = string;

export enum ChatMessageContentType {
  TEXT = "TEXT",
  EMOJI = "EMOJI",
  TYPING = "TYPING",
  ASR = "ASR",
  TOGGLE_SPEECH = "TOGGLE_SPEECH",
  BOT_LIST = "BOT_LIST",
  USER_BARGE_IN = "USER_BARGE_IN",
}

export enum AuthorType {
  BOT = "BOT",
  USER = "USER",
  SYSTEM = "SYSTEM",
}

export interface ChatMessageTextContent {
  type: ChatMessageContentType.TEXT;
  messageID: MessageID;
  text: string;
  botName: string | null;
}

export interface ChatMessageEmojiContent {
  type: ChatMessageContentType.EMOJI;
  messageID: MessageID;
  emoji: string;
  title: string;
  botName: string | null;
}

interface ChatMessageTypingContent {
  type: ChatMessageContentType.TYPING;
  messageID: MessageID;
  text: string | null;
  isNewMessage: boolean;
}

interface ChatMessageUserBargeInContent {
  type: ChatMessageContentType.USER_BARGE_IN;
}

interface ASRContent {
  type: ChatMessageContentType.ASR;
  transcript: string;
  messageID: string;
}

interface BotList {
  type: ChatMessageContentType.BOT_LIST;
  botList: string[];
}

interface ToggleSpeechContent {
  type: ChatMessageContentType.TOGGLE_SPEECH;
  interactionMode: InteractionMode;
}

export interface BotChatMessage {
  author: AuthorType.BOT;
  content:
    | ChatMessageTextContent
    | ChatMessageEmojiContent
    | ChatMessageTypingContent
    | ChatMessageUserBargeInContent
    | ASRContent
    | BotList;
}

export enum SystemMessageContent {
  SHUTDOWN = "SHUTDOWN",
  CONFIG_CHANGE = "CONFIG_CHANGE",
}

export interface ServerConfig {
  type: SystemMessageContent.CONFIG_CHANGE;
  speechSupported: boolean;
}

export interface SystemShutdown {
  type: SystemMessageContent.SHUTDOWN;
  reason: string;
}

export interface SystemConfigMessage {
  author: AuthorType.SYSTEM;
  content: ServerConfig | SystemShutdown;
}

export interface SystemShutdownMessage {
  author: AuthorType.SYSTEM;
  content: SystemShutdown;
}

export type BotChatTextMessage = BotChatMessage & {
  content: ChatMessageTextContent;
};

export type BotChatEmojiMessage = BotChatMessage & {
  content: ChatMessageEmojiContent;
};

export type UserChatTextMessage = UserChatMessage & {
  content: ChatMessageTextContent;
};

export type UserChatToggleSpeechMessage = UserChatMessage & {
  content: ToggleSpeechContent;
};

export interface UserChatMessage {
  author: AuthorType.USER;
  content:
    | ChatMessageTextContent
    | ChatMessageTypingContent
    | ToggleSpeechContent;
}

export enum InteractionMode {
  TEXT = "Text",
  SPEECH = "Speech",
}
