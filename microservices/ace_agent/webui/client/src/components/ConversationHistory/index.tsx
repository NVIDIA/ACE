
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

import { useEffect, useRef } from "react";
import {
  BotChatMessage,
  ChatMessageContentType,
  UserChatMessage,
} from "../../../../shared/types";

import "./index.css";
import ConversationMessage from "../ConversationMessage";
import Loading from "../Loading";

interface Props {
  messages: (UserChatMessage | BotChatMessage)[];
  selectedBot: string | null;
  isBotTyping: boolean;
}

export default function ConversationHistory({
  messages,
  isBotTyping,
  selectedBot,
}: Props) {
  const bottom = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottom.current?.scrollIntoView();
  }, [messages, isBotTyping]);

  return (
    <div className="conversation-history">
      {messages.map((message, i) => renderMessage(message, selectedBot, i))}
      {isBotTyping && (
        <div className="message bot-text">
          <Loading />
        </div>
      )}
      <div ref={bottom} />
    </div>
  );
}

function renderMessage(
  message: UserChatMessage | BotChatMessage,
  selectedBot: string | null,
  index: number
) {
  if (
    message.content.type !== ChatMessageContentType.TEXT &&
    message.content.type !== ChatMessageContentType.EMOJI
  ) {
    return null;
  }
  if (selectedBot && message.content.botName !== selectedBot) {
    return null;
  }

  if (message.content)
    return (
      <ConversationMessage
        authorType={message.author}
        messageContent={message.content}
        key={index}
      />
    );
}
