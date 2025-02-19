
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

import { useRef } from "react";

const MIN_INT16_VALUE = -32768;
const MAX_INT16_VALUE = 32767;
const SAMPLE_RATE_HZ = 44100;
const AUDIO_BUFFER_LENGTH_SEC = 60;

class AudioPlayer {
  private enabled: boolean = false;
  private timerID: NodeJS.Timeout | null = null;
  private offset: number = 0;
  private currentAudioSequenceDuration: number = 0;
  private currentAudioSequenceStartedAt: number = 0;
  private audioBuffer: AudioBuffer;
  private source: AudioBufferSourceNode;
  private audioCtx: AudioContext;
  private timeUntilAudioCompleted: number = 0;

  constructor(audioCtx: AudioContext) {
    this.audioCtx = audioCtx;
    this.audioBuffer = this.createNewAudioBuffer();
    this.source = audioCtx.createBufferSource();
    this.source.buffer = this.audioBuffer;
    this.source.connect(audioCtx.destination);
  }
  enable(): void {
    this.enabled = true;
  }
  disable(): void {
    this.enabled = false;
  }

  play(buffer: Int16Array): void {
    if (!this.enabled) {
      return;
    }
    const channel = this.audioBuffer.getChannelData(0); // mono channel

    // We receive the data in unsigned 16-bit words. AudioBuffer must
    // be in 32-bit floats between -1.0 and 1.0. To convert, normalize
    // each sample
    for (let i = 0; i < buffer.length; i++) {
      if (buffer[i] > 0) {
        channel[i + this.offset] = buffer[i] / MAX_INT16_VALUE;
      } else {
        channel[i + this.offset] = buffer[i] / -MIN_INT16_VALUE;
      }
    }

    // If this is the first chunk of audio since the player was last reset, immediately
    // start playing the source. Additional chunks will be appended to the buffer as
    // they come
    if (this.offset === 0) {
      this.currentAudioSequenceStartedAt = performance.now();
      this.source.start();
    }
    this.offset += buffer.length;

    // We set a timer that will reset the audio buffer after the audio sequence has been
    // played. We cannot predetermine the duration of the audio sequence, because more
    // audio chunks may be added after the audio has started playing. For this reason,
    // every time a chunk is added to the buffer, we clear the existing timer, recompute
    // the duration of the audio sequence, and create a new timer with the appropriate
    // audio sequence duration.
    if (this.timerID) {
      clearTimeout(this.timerID);
    }
    const chunkDuration = buffer.length / SAMPLE_RATE_HZ;
    this.currentAudioSequenceDuration += chunkDuration;
    const audioEllapsed =
      (performance.now() - this.currentAudioSequenceStartedAt) / 1000;

    this.timeUntilAudioCompleted =
      this.currentAudioSequenceDuration - audioEllapsed;
    this.timerID = setTimeout(
      () => this.reset(),
      this.timeUntilAudioCompleted * 1000
    );
  }

  private createNewAudioBuffer(): AudioBuffer {
    return this.audioCtx.createBuffer(
      1,
      SAMPLE_RATE_HZ * AUDIO_BUFFER_LENGTH_SEC,
      SAMPLE_RATE_HZ
    );
  }

  private reset(): void {
    this.offset = 0;
    this.source.disconnect();
    this.audioBuffer = this.createNewAudioBuffer();
    this.currentAudioSequenceDuration = 0;
    this.currentAudioSequenceStartedAt = 0;
    this.timeUntilAudioCompleted = 0;
    this.source = this.audioCtx.createBufferSource();
    this.source.buffer = this.audioBuffer;
    this.source.connect(this.audioCtx.destination);
  }

  public getSource(): AudioBufferSourceNode {
    return this.source;
  }

  // Immediately stops playing audio. Audio left in the buffer is erased
  public interrupt(): void {
    if (this.timerID) {
      clearTimeout(this.timerID);
    }
    this.reset();
  }
}

export default function useAudioPlayer(audioCtx: AudioContext): AudioPlayer {
  const audioPlayerRef = useRef<AudioPlayer>(new AudioPlayer(audioCtx));
  return audioPlayerRef.current;
}
