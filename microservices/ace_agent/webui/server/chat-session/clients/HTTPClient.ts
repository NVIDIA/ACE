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

import { HTTP_CHAT_URL } from "../../config.js";

/**
 * Provides an HTTP client to a domain URL that must be provided through the HTTP_CHAT_URL
 * environment variable. The client is a think wrapper around the native `fetch()` API,
 * that only pre-sets the domain name for convenience
 *
 * Example:
 *  // HTTP_CHAT_URL = http://localhost:8080
 * await fetch('/chat') // sends a request to http://localhost:8080/chat
 */
class HTTPClient {
  get(): { fetch: typeof fetch } {
    function _fetch(url: string, data: Parameters<typeof fetch>["1"]) {
      return fetch(HTTP_CHAT_URL + url, data);
    }
    return { fetch: _fetch };
  }

  isAvailable(): boolean {
    return !!HTTP_CHAT_URL;
  }
}

export default new HTTPClient();
