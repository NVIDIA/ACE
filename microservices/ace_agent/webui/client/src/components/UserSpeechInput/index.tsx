
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

import { MicAccessState, MicrophoneState } from "../../utils/useMicrophone";
import useRealTimeVolume from "../../utils/useRealTimeVolume";
import useRequestAnimationFrame from "../../utils/useRequestAnimationFrame";
import TextInput from "../TextInput";
import Loading from "../Loading";
import "./index.css";

interface Props {
  micState: MicrophoneState;
  onEnableMic: () => void;
  onDisableMic: () => void;
  audioSource: AudioNode | null;
}

export default function UserSpeechInput({
  micState,
  onEnableMic,
  onDisableMic,
  audioSource,
}: Props) {
  const isError = micState.micAccessState === MicAccessState.ERROR;
  const isLoading = micState.micAccessState === MicAccessState.LOADING;
  const isMicEnabled = micState.isRecording;

  const realTimeVolume = useRealTimeVolume(audioSource, 5);
  useRequestAnimationFrame();

  const isUserActivelySpeaking = realTimeVolume !== 0;

  const styles: React.CSSProperties = {};
  if (isMicEnabled && isUserActivelySpeaking) {
    styles[
      "boxShadow"
    ] = `0 0 0px ${realTimeVolume}px var(--bot-volume-active-box-shadow-bg)`;
    styles["borderColor"] = "var(--active-audio-border-color)";
  }

  function onClickMic() {
    if (micState.isRecording) {
      onDisableMic();
    } else {
      onEnableMic();
    }
  }

  const [icon, title] = micIcon(isLoading, isError, isMicEnabled);

  return (
    <div className="user-speech-input-area">
      <button
        className="mic-button"
        onClick={onClickMic}
        disabled={isError}
        style={styles}
        title={title}
      >
        {icon}
      </button>
    </div>
  );
}

function micIcon(
  isLoading: boolean,
  isError: boolean,
  isMicEnabled: boolean
): [JSX.Element, string] {
  if (isLoading) {
    return [<Loading />, "accessing microphone..."];
  }
  if (isError) {
    return [
      <span className="material-symbols-outlined">priority_high</span>,
      "an error occurred while accessing the microphone",
    ];
  }
  if (isMicEnabled) {
    return [
      <span className="material-symbols-outlined">mic</span>,
      "The microphone is enabled. Click to mute",
    ];
  }
  return [
    <span className="material-symbols-outlined">mic_off</span>,
    "The microphone is disabled. Click to unmute",
  ];
}
