
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
import { FormEventHandler } from "react";
import { ConnectionState } from "../../utils/useServerState";
import TextInput from "../TextInput";

interface Props {
  onSubmit: FormEventHandler<HTMLFormElement>;
  textQuery: string;
  onChangeTextQuery: (query: string) => void;
  connectionState: ConnectionState;
}

export default function UserTextInput({
  textQuery,
  onChangeTextQuery,
  onSubmit,
  connectionState,
}: Props) {
  const placeholder = getPlaceholder(connectionState);
  const isEnabled = getIsEnabled(connectionState);
  const isTextEmpty = textQuery.trim().length === 0;
  console.log(connectionState);
  return (
    <form className="user-controls-form" onSubmit={onSubmit}>
      <TextInput
        value={textQuery}
        placeholder={placeholder}
        onChange={(e) => onChangeTextQuery(e.target.value)}
        disabled={!isEnabled}
        className="user-input-field"
      />
      <input
        type="submit"
        className="user-input-submit"
        value="Send"
        disabled={!isEnabled || isTextEmpty}
      ></input>
    </form>
  );
}

function getPlaceholder(connectionState: ConnectionState): string {
  switch (connectionState) {
    case ConnectionState.INITIAL:
      return "Connecting to the server...";
    case ConnectionState.CLOSED:
      return "The connection to the server was closed. Please refresh the page";
    case ConnectionState.ERROR:
      return "An error occurred. Please refresh the page";
    case ConnectionState.READY:
      return "Type your reply";
  }
}

function getIsEnabled(connectionState: ConnectionState): boolean {
  switch (connectionState) {
    case ConnectionState.INITIAL:
    case ConnectionState.CLOSED:
    case ConnectionState.ERROR:
      return false;
    case ConnectionState.READY:
      return true;
  }
}
