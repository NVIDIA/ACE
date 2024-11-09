
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

import { useEffect } from "react";
import "./index.css";

interface Option {
  value: string;
  disabled?: boolean;
  disabledReason?: string;
}

interface Props {
  options: Option[];
  selectedOption: string | null;
  onChangeOption: (option: string | null) => void;
}
export default function Toggle({
  options,
  selectedOption,
  onChangeOption,
}: Props) {
  useEffect(() => {
    const optionValues = options.map((option) => option.value);
    if (!selectedOption || !optionValues.includes(selectedOption)) {
      onChangeOption(optionValues[0] ?? null);
    }
  }, [options]);

  if (options.length === 0) {
    return null;
  }

  function getPillClassName(pill: string): string {
    return "pill " + (pill === selectedOption ? "selected" : "");
  }

  return (
    <div className="toggle">
      {options.map((option) => (
        <button
          className={getPillClassName(option.value)}
          onClick={() => onChangeOption(option.value)}
          key={option.value}
          disabled={option.disabled ?? false}
          title={option.disabled ? option.disabledReason : ""}
        >
          {option.value}
        </button>
      ))}
    </div>
  );
}
