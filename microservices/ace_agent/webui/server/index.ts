
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

import { WebSocketServer } from "ws";
import * as https from "node:https";
import * as fs from "fs";

import EmojiFinder from "./emoji-finder/index.js";
import ChatSessionTask from "./chat-session/tasks/ChatSessionTask.js";

import { EMOJI_FILE_PATH, SERVER_PORT } from "./config.js";
import getLogger from "./chat-session/logger.js";

const MAX_CLI_ARGS = 10;

const logger = getLogger("main");

async function initEmojiFinder(): Promise<EmojiFinder> {
  if (!EMOJI_FILE_PATH) {
    logger.info("No EMOJI_FILE_PATH found. Emojis will be disabled");
    return null;
  }
  logger.info("Loading emojis from file %s", EMOJI_FILE_PATH);
  const emojiFinder = EmojiFinder.fromEmojiFile(EMOJI_FILE_PATH);
  logger.info(
    "Initializing emoji finder... (can take several minutes on initial run)"
  );
  await emojiFinder.init();
  logger.info("Emoji finder ready");
  return emojiFinder;
}

function getCLIArgument(
  name: string,
  optional: boolean = true
): string | boolean {
  // Get command-line arguments, excluding the first two (node and script path)
  const args = process.argv.slice(2);

  if (args.length > MAX_CLI_ARGS) {
    // Ensure the user doesn't pass too many arguments. This is to address a vulnerability
    // flagged in checkmarkx
    throw new Error(
      `Too many arguments. Expected max ${MAX_CLI_ARGS} but got ${args.length}`
    );
  }

  for (let i = 0; i < MAX_CLI_ARGS; i++) {
    if (!args[i]) {
      break;
    }
    if (args[i] === `--${name}`) {
      if (args[i + 1]) {
        return args[i + 1]; // Return the next argument as the value
      } else {
        return true;
      }
    }
  }

  if (!optional) {
    throw new Error(
      `Expected argument --${name}. Run the command with --help for detailed usage`
    );
  }
}

function printHelp(): void {
  process.stdout.write("Runs the websocket server for the bot web UI. The\n");
  process.stdout.write("browser client communicates with the client through\n");
  process.stdout.write("websockets. The webserver interacts with ACE Agent\n");
  process.stdout.write("through its redis, gRPC or http APIs.\n\n");
  process.stdout.write("Arguments:\n");
  process.stdout.write("--ace-agent-text-chat-interface: Required. which\n");
  process.stdout.write("  interface of ACE Agent to use. Must be one of\n");
  process.stdout.write('  event (aka "redis", "umim"), grpc or server\n');
  process.stdout.write('  (aka "http"). The endpoints can be configured\n');
  process.stdout.write("  using environment variables: REDIS_URL, GRPC_URL\n");
  process.stdout.write("  and HTTP_CHAT_URL.\n");

  process.stdout.write("--speech: Optional. Whether the UI should allow\n");
  process.stdout.write("  speech conversations. Requires ACE Agent to run\n");
  process.stdout.write("  in speech mode. The endpoint defined in the\n");
  process.stdout.write("  GRPC_URL environment variable will be used to\n");
  process.stdout.write("  stream audio.\n\n");
}

function createSecureWebsocketServer(
  cert_path: string,
  key_path: string
): WebSocketServer {
  const server = https.createServer({
    cert: fs.readFileSync(cert_path),
    key: fs.readFileSync(key_path),
  }).listen(SERVER_PORT);

  return new WebSocketServer({ server });
}

function createInsecureWebsocketServer(): WebSocketServer {
  return new WebSocketServer({ port: SERVER_PORT });
}

function createWebsocketServer(): WebSocketServer {
  if (process.env.SSL_CERT_PATH || process.env.SSL_KEY_PATH) {
    if (!process.env.SSL_CERT_PATH || !process.env.SSL_KEY_PATH) {
      logger.warn(
        "Missing environment variable SSL_CERT_PATH or SSL_KEY_PATH. Creating insecure websocket server (ws://)"
      );
      return createInsecureWebsocketServer();
    }
    logger.info(
      "SSL_CERT_PATH and SSL_KEY_PATH environment variables were found. Creating a secure websocket server (wss://)"
    );
    return createSecureWebsocketServer(
      process.env.SSL_CERT_PATH,
      process.env.SSL_KEY_PATH
    );
  }

  logger.info('Did not find environment variables SSL_CERT_PATH or SSL_KEY_PATH. Creating insecure websocket server (ws://)')
  return createInsecureWebsocketServer();
}

async function run(): Promise<void> {
  const help = getCLIArgument("help");
  if (help) {
    printHelp();
    return;
  }
  const aceAgentTextChatInterface = getCLIArgument(
    "ace-agent-text-chat-interface",
    false
  );
  if (
    aceAgentTextChatInterface !== "server" &&
    aceAgentTextChatInterface !== "grpc" &&
    aceAgentTextChatInterface !== "event"
  ) {
    throw new Error(
      `--ace-agent-text-chat-interface argument must be one of server, grpc or event. Got ${aceAgentTextChatInterface} instead`
    );
  }

  const isSpeechEnabled = !!getCLIArgument("speech");
  const wss = createWebsocketServer();

  // Emoji finder is only used in event mode. Do not load emojis in other modes
  const emojiFinder =
    aceAgentTextChatInterface === "event" ? await initEmojiFinder() : null;

  logger.info(`Web server up and running on port ${SERVER_PORT}!`);

  wss.on("connection", async function connection(ws) {
    ws.binaryType = "arraybuffer";

    const session = new ChatSessionTask(
      ws,
      emojiFinder,
      aceAgentTextChatInterface as "server" | "grpc" | "event",
      isSpeechEnabled
    );
    logger.info(
      "New user connected! Created session with stream_id=%s",
      session.getStreamID()
    );
    session.start();
  });
}

run();
