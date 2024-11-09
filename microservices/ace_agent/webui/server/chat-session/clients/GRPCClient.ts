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

import { GRPC_URL } from "../../config.js";
import { PromiseClient, createPromiseClient } from "@connectrpc/connect";
import { createGrpcTransport } from "@connectrpc/connect-node";
import { AceAgentGrpc } from "../../grpc/gen/ace_agent_connect.js";

type GRPCClient = PromiseClient<typeof AceAgentGrpc>;

/**
 * Provides a gRPC client to a specified GRPC_URL, which must be provided as an
 * enviornment variable. The object is a singleton, meaning that at most one client will
 * be created, and the same client will be returned to each `.get()` call
 */
class GRPCClientSingleton {
  private client: GRPCClient = null;

  get(): GRPCClient {
    if (this.client) {
      return this.client;
    }
    this.client = createPromiseClient(
      AceAgentGrpc,
      createGrpcTransport({
        baseUrl: GRPC_URL,
        httpVersion: "2",
      })
    );
    return this.client;
  }

  isAvailable(): boolean {
    return !!GRPC_URL;
  }
}

export default new GRPCClientSingleton();
