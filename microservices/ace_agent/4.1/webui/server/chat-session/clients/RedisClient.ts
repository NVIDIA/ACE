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

import { createClient } from "redis";
import { REDIS_URL } from "../../config.js";

type RedisClient = ReturnType<typeof createClient>;

class RedisClientSingleton {
  private client: RedisClient = null;

  async get(): Promise<RedisClient> {
    if (this.client) {
      return this.client;
    }

    this.client = createClient({
      url: REDIS_URL,
    });
    await this.client.connect();
    return this.client;
  }

  isAvailable(): boolean {
    return !!REDIS_URL;
  }
}

export default new RedisClientSingleton();
