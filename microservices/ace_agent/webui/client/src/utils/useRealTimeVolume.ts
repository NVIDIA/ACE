
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
const FFT_SIZE = 256;
const dataArray = new Float32Array(FFT_SIZE / 2);

export default function useRealTimeVolume(
  source: AudioNode | null,
  threshold: number = 0
): number {
  const analyzerRef = useRef<AnalyserNode>();

  useEffect(() => {
    console.log("New source! Creating new analyzer");
    if (source) {
      analyzerRef.current = source.context.createAnalyser();
      analyzerRef.current.fftSize = FFT_SIZE;
      source.connect(analyzerRef.current);
    }
  }, [source]);

  const analyzer = analyzerRef.current;
  if (!analyzer) {
    return 0;
  }
  analyzer.getFloatFrequencyData(dataArray);
  if (Number.isFinite(dataArray[10])) {
    const volume = Math.max(0, dataArray[10] + 120) / 5;
    return volume > threshold ? volume : 0;
  }
  return 0;
}
