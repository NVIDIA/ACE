
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
import useServerState from "../../utils/useServerState";
import { FormEvent, useState } from "react";
import ConversationHistory from "../ConversationHistory";
import { InteractionMode, MessageID } from "../../../../shared/types";
import AppHeader from "../AppHeader";
import UserSpeechInput from "../UserSpeechInput";
import UserTextInput from "../UserTextInput";
import useMicrophone from "../../utils/useMicrophone";
import useAudioPlayer from "../../utils/useAudioPlayer";
import BotFace from "../BotFace";
import {
  BOT_AUDIO_CONTEXT,
  USER_AUDIO_CONTEXT,
} from "../../utils/audio-contexts";
import useToastNotices from "../../utils/useToastNotices";
import ToastNotices from "../ToastNotices";

function App() {
  const audioPlayer = useAudioPlayer(BOT_AUDIO_CONTEXT);
  const toastNotices = useToastNotices();
  const onReceiveAudio = (chunk: Int16Array) => audioPlayer.play(chunk);
  const onSystemShutdown = (reason: string) =>
    toastNotices.addToast(reason, "fatal");
  const onWebSocketError = (e: Error) =>
    toastNotices.addToast(e.message, "fatal");
  const onMicrophoneWarning = (content: string) =>
    toastNotices.addToast(content, "warning");
  const onUserBargeIn = () => audioPlayer.interrupt();
  const server = useServerState(
    onReceiveAudio,
    onSystemShutdown,
    onWebSocketError,
    onUserBargeIn
  );
  const microphone = useMicrophone(
    server.sendUserAudio,
    onMicrophoneWarning,
    USER_AUDIO_CONTEXT
  );

  const [textQuery, setTextQuery] = useState<string>("");
  const [messageID, setMessageID] = useState<MessageID | null>(null);
  const [selectedBot, setSelectedBot] = useState<string | null>(null);
  const [interactionMode, setInteractionMode] = useState<InteractionMode>(
    InteractionMode.TEXT
  );

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    server.sendChatMessage(messageID!, textQuery, selectedBot);
    setTextQuery("");

    // Reset the chat message ID, so that a new message ID is generated
    // when the user starts typing the next reply
    setMessageID(null);
  }

  function onChangeTextQuery(value: string) {
    const isNewMessage = messageID == null;
    const id =
      messageID ??
      Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString();
    server.sendUserTyping(id, value, isNewMessage);
    setMessageID(id);
    setTextQuery(value);
  }

  function onChangeInteractionMode(mode: InteractionMode): void {
    if (mode === InteractionMode.SPEECH) {
      audioPlayer.enable();
      microphone.startRecording();
    } else {
      audioPlayer.disable();
      microphone.stopRecording();
    }
    server.toggleSpeech(mode);
    setInteractionMode(mode);
  }

  return (
    <div className="app">
      <AppHeader
        interactionMode={interactionMode}
        onChangeInteractionMode={onChangeInteractionMode}
        selectedBot={selectedBot}
        onChangeSelectedBot={setSelectedBot}
        botList={server.serverState.botList}
        isSpeechSupported={
          server.serverState.serverConfig?.speechSupported ?? false
        }
      />
      <div className="conversation">
        {interactionMode === InteractionMode.TEXT ? (
          <ConversationHistory
            messages={server.serverState.messages}
            isBotTyping={server.serverState.isBotTyping}
            selectedBot={selectedBot}
          />
        ) : (
          <BotFace
            emoji={server.serverState.latestBotEmoji}
            messages={server.serverState.messages}
            isBotTyping={server.serverState.isBotTyping}
            audioSource={audioPlayer.getSource()}
          />
        )}
      </div>
      <div className="user-controls-area">
        <div className="user-controls">
          {interactionMode === InteractionMode.TEXT ? (
            <UserTextInput
              onSubmit={onSubmit}
              textQuery={textQuery}
              onChangeTextQuery={onChangeTextQuery}
              connectionState={server.serverState.connectionState}
            />
          ) : (
            <UserSpeechInput
              micState={microphone.microphoneState}
              onEnableMic={microphone.startRecording}
              onDisableMic={microphone.stopRecording}
              audioSource={microphone.source}
            />
          )}
        </div>
      </div>
      <ToastNotices toasts={toastNotices.toasts} />
    </div>
  );
}

export default App;
