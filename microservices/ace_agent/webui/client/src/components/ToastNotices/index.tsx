
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

import useRerender from "../../utils/useRerender";
import { ToastNotice } from "../../utils/useToastNotices";
import "./index.css";

interface Props {
  toasts: ToastNotice[];
}

export default function ToastNotices(props: Props) {
  // Rerender this component every 60 seconds, so that the "xx minutes ago" is re-calculated
  useRerender(60);
  return (
    <div className="toast-notices">
      {props.toasts.reverse().map((toast) => (
        <div className={`toast-notice ${toast.level}`}>
          {toast.content}
          <time className="toast-timestamp">
            {relativeTime(toast.timestamp)}
          </time>
        </div>
      ))}
    </div>
  );
}

function relativeTime(timestamp: number): string {
  const diff = Math.floor((timestamp - Date.now()) / (60 * 1000));
  if (diff === 0) {
    return "less than a minute ago";
  }
  const format = new Intl.RelativeTimeFormat("en", { style: "long" });
  return format.format(diff, "minute");
}
