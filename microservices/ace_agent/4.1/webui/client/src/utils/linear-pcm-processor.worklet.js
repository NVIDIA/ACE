
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

class LinearPCMProcessor extends AudioWorkletProcessor {
  // The size of the buffer in miliseconds. An audio block is posted to the main thread
  // every time the buffer is full, which means a large buffer will emit less frequently
  // (higher latency), but more efficiently (fewer I/O interruptions between the worker
  // and the main thread)
  static BUFFER_SIZE_MS = 80;

  constructor() {
    super();
    // the "sampleRate" is available on the global scope in AudioWorklet files. The linter
    // doesn't know that, so it incorrectly raises an error when accessing it. The comment
    // below disables the linter for that specific line.
    // eslint-disable-next-line no-undef
    const rate = sampleRate;

    const bufferSize = (rate / 1000) * LinearPCMProcessor.BUFFER_SIZE_MS;
    this.buffer = new Int16Array(bufferSize);
    this.offset = 0;
  }

  /**
   * Converts input data from Float32Array to Int16Array, and stores it to
   * to the buffer. When the buffer is full, its content is posted to the main
   * thread, and the buffer is emptied
   */
  process(inputList, _outputList, _parameters) {
    // Assumes the input is mono (1 channel). If there are more channels, they
    // are ignored
    const input = inputList[0][0]; // first channel of first input

    for (let i = 0; i < input.length; i++) {
      const sample = Math.max(-1, Math.min(1, input[i]));
      this.buffer[i + this.offset] =
        sample < 0 ? sample * 0x8000 : sample * 0x7fff;
    }
    this.offset += input.length;

    // Once the buffer is filled entirely, flush the buffer
    if (this.offset >= this.buffer.length - 1) {
      this.flush();
    }
    return true;
  }

  /**
   * Sends the buffer's content to the main thread via postMessage(), and reset
   * the offset to 0
   */
  flush() {
    this.offset = 0;
    this.port.postMessage(this.buffer);
  }
}

registerProcessor("linear-pcm-processor", LinearPCMProcessor);
