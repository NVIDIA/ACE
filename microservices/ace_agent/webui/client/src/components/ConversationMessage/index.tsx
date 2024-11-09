
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

import "./index.css";

import {
  AuthorType,
  ChatMessageContentType,
  ChatMessageEmojiContent,
  ChatMessageTextContent,
} from "../../../../shared/types";

type Author = AuthorType.USER | AuthorType.BOT;
type MessageContent = ChatMessageTextContent | ChatMessageEmojiContent;

interface Props {
  authorType: Author;
  messageContent: MessageContent;
}

export default function ConversationMessage({
  authorType,
  messageContent,
}: Props) {
  return (
    <div
      className={`message ${getMessageClassName(authorType, messageContent)}`}
      title={getMessageTitle(messageContent) ?? undefined}
    >
      {getMessageContent(messageContent)}
    </div>
  );
}

function getMessageContent(messageContent: MessageContent): string {
  switch (messageContent.type) {
    case ChatMessageContentType.TEXT:
      return messageContent.text;
    case ChatMessageContentType.EMOJI:
      return messageContent.emoji;
  }
}

function getMessageClassName(
  authorType: Author,
  messageContent: MessageContent
): string {
  switch (authorType) {
    case AuthorType.USER:
      return "user-text";
    case AuthorType.BOT:
      return messageContent.type === ChatMessageContentType.TEXT
        ? "bot-text"
        : "bot-emoji";
  }
}

/**
 * Which title attribute to set to the message wrapper. Currently, this is only used for
 * emoji messages
 */
function getMessageTitle(messageContent: MessageContent): string | null {
  if (messageContent.type === ChatMessageContentType.EMOJI) {
    return messageContent.title;
  }
  return null;
}
