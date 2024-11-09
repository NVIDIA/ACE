
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

import { useReducer, useRef } from "react";
import workletUrl from "./linear-pcm-processor.worklet.js?url";

export interface MicrophoneState {
  micAccessState: MicAccessState;
  error: Error | null;
  isRecording: boolean;
}

enum MicrophoneActionType {
  MIC_ACCESS_REQUESTED = "MIC_ACCESS_REQUESTED",
  MIC_ACCESS_GRANTED = "MIC_ACCESS_GRANTED",
  MIC_ACCESS_ERROR = "MIC_ACCESS_ERROR",
  RECORDING_STARTED = "RECORDING_STARTED",
  RECORDING_STOPPED = "RECORDING_STOPPED",
}

export enum MicAccessState {
  INITIAL = "INITIAL",
  LOADING = "LOADING",
  GRANTED = "GRANTED",
  ERROR = "ERROR",
}

interface MicrophoneStateActionMicAccessRequested {
  type: MicrophoneActionType.MIC_ACCESS_REQUESTED;
}

interface MicrophoneStateActionMicAccessGranted {
  type: MicrophoneActionType.MIC_ACCESS_GRANTED;
}

interface MicrophoneStateActionMicAccessError {
  type: MicrophoneActionType.MIC_ACCESS_ERROR;
  payload: Error;
}
interface MicrophoneStateActionRecordingStarted {
  type: MicrophoneActionType.RECORDING_STARTED;
}

interface MicrophoneStateActionRecordingStopped {
  type: MicrophoneActionType.RECORDING_STOPPED;
}

type MicrophoneStateAction =
  | MicrophoneStateActionMicAccessRequested
  | MicrophoneStateActionMicAccessGranted
  | MicrophoneStateActionMicAccessError
  | MicrophoneStateActionRecordingStarted
  | MicrophoneStateActionRecordingStopped;

function reducer(
  state: MicrophoneState,
  action: MicrophoneStateAction
): MicrophoneState {
  switch (action.type) {
    case MicrophoneActionType.MIC_ACCESS_REQUESTED:
      return { ...state, micAccessState: MicAccessState.LOADING };
    case MicrophoneActionType.MIC_ACCESS_GRANTED:
      return {
        ...state,
        micAccessState: MicAccessState.GRANTED,
      };
    case MicrophoneActionType.MIC_ACCESS_ERROR:
      return {
        ...state,
        micAccessState: MicAccessState.ERROR,
        error: action.payload,
      };
    case MicrophoneActionType.RECORDING_STARTED:
      return {
        ...state,
        isRecording: true,
      };
    case MicrophoneActionType.RECORDING_STOPPED:
      return {
        ...state,
        isRecording: false,
      };
    default:
      return state;
  }
}

const INITIAL_STATE: MicrophoneState = {
  micAccessState: MicAccessState.INITIAL,
  error: null,
  isRecording: false,
};

export default function useMicrophone(
  onAudioChunkAvailable: (buffer: ArrayBuffer) => void,
  onWarning: (content: string) => void,
  audioCtx: AudioContext
): {
  microphoneState: MicrophoneState;
  startRecording: () => Promise<void>;
  stopRecording: () => void;
  source: AudioNode | null;
} {
  const [microphoneState, dispatch] = useReducer(reducer, INITIAL_STATE);
  const audioSourceRef = useRef<AudioNode>();

  async function requestAccess() {
    dispatch({
      type: MicrophoneActionType.MIC_ACCESS_REQUESTED,
    });
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { deviceId: "default" },
      });
      const allDevices = await navigator.mediaDevices.enumerateDevices();
      const deviceID = stream.getAudioTracks()[0].getSettings().deviceId;
      const selectedDevice = allDevices.find(
        (device) => device.deviceId === deviceID
      );

      const selectedDeviceLabel = selectedDevice?.label.toLowerCase();
      if (
        selectedDeviceLabel?.includes("bluetooth") ||
        selectedDeviceLabel?.includes("wireless")
      ) {
        onWarning(
          `It looks like you might be using a bluetooth microphone or headset (name: ${selectedDeviceLabel}). If you experience low-quality speech recognition, consider switching to a wired microphone or headset in your system's settings`
        );
      }

      audioSourceRef.current = audioCtx.createMediaStreamSource(stream);
      await audioCtx.audioWorklet.addModule(workletUrl);
      const audioWorkletNode = new AudioWorkletNode(
        audioCtx,
        "linear-pcm-processor"
      );
      audioSourceRef.current.connect(audioWorkletNode);
      audioWorkletNode.connect(audioCtx.destination);
      audioWorkletNode.port.onmessage = (e: MessageEvent<ArrayBuffer>) => {
        onAudioChunkAvailable(e.data);
      };
      dispatch({
        type: MicrophoneActionType.MIC_ACCESS_GRANTED,
      });
    } catch (e) {
      console.error(e);
      dispatch({
        type: MicrophoneActionType.MIC_ACCESS_ERROR,
        payload: e as Error,
      });
    }
  }

  async function startRecording() {
    if (microphoneState.micAccessState !== MicAccessState.GRANTED) {
      await requestAccess();
    }
    console.log("resuming...");
    audioCtx.resume();
    dispatch({
      type: MicrophoneActionType.RECORDING_STARTED,
    });
  }

  function stopRecording() {
    audioCtx.suspend();
    dispatch({
      type: MicrophoneActionType.RECORDING_STOPPED,
    });
  }

  return {
    microphoneState,
    startRecording,
    stopRecording,
    source: audioSourceRef.current ?? null,
  };
}
