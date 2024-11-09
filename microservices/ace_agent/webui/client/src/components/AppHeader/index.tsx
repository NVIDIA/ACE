
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

import { InteractionMode } from "../../../../shared/types";
import Toggle from "../Toggle";
import "./index.css";

interface Props {
  interactionMode: InteractionMode;
  onChangeInteractionMode: (mode: InteractionMode) => void;
  botList: string[];
  selectedBot: string | null;
  onChangeSelectedBot: (bot: string | null) => void;
  isSpeechSupported: boolean;
}
export default function AppHeader({
  interactionMode,
  onChangeInteractionMode,
  botList,
  selectedBot,
  onChangeSelectedBot,
  isSpeechSupported,
}: Props) {
  return (
    <div className="app-header">
      <h1 className="app-title">ACE Agent Bot Web UI</h1>
      <div className="app-controls">
        <Toggle
          options={botList.map((bot) => ({ value: bot }))}
          selectedOption={selectedBot}
          onChangeOption={onChangeSelectedBot}
        />

        <Toggle
          options={[
            {
              value: InteractionMode.SPEECH,
              disabled: !isSpeechSupported,
              disabledReason:
                "Speech mode is disabled. Run the server with --speech to enable speech",
            },
            { value: InteractionMode.TEXT },
          ]}
          selectedOption={interactionMode}
          onChangeOption={(option) =>
            onChangeInteractionMode(option as InteractionMode)
          }
        />
      </div>
    </div>
  );
}
