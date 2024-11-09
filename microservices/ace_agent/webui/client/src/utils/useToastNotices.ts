
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

import { useState } from "react";

type ToastContent = string;

export type ToastNotice = {
  content: ToastContent;
  timestamp: number;
  level: ToastNoticeLevel;
};

export type ToastNoticeLevel = "fatal" | "warning";

/**
 * A custom React hook to manage "toast" notices. These notices appear in the web UI as
 * popup messages. The toasts must be rendered by the <ToastNotices /> component
 * @returns
 */
export default function useToastNotices(): {
  toasts: ToastNotice[];
  addToast: (newToast: ToastContent, level: ToastNoticeLevel) => void;
} {
  const [toasts, setToasts] = useState<ToastNotice[]>([]);

  function addToast(newToastContent: ToastContent, level: ToastNoticeLevel) {
    const newToast = {
      content: newToastContent,
      timestamp: Date.now(),
      level,
    };
    setToasts([...toasts, newToast]);
  }
  return { toasts, addToast };
}
