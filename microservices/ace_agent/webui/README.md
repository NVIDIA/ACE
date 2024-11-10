<!--
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
-->
# ACE Agent Bot Web UI

This is a web UI to interact with ACE Agent bots through text and speech.

## Features overview

ACE Agent UI is a web application to converse with ACE Agent bots using text or speech. This section describes the key features of the web application.

### Text conversations

The bot UI supports text-based conversations.

### Speech conversations

The Bot Web UI supports conversing with ACE Agent bots in `speech` mode. In this mode, the user can speak through their microphone, and hear back audio from the bot. The user can view their own audio transcript (ASR) in real time, as well as the bot’s speech transcript.

![Screenshot of a speech interaction in the bot web UI](./images/screenshot_speech.png)

### Emojis

In addition to speech and text, some bots can express themselves through gestures and emotions. To represent these non-verbal signals, the bot web UI translates gestures to emojis.

| ![Screenshot of emojis in speech mode](images/screenshot_emoji_speech.png) | ![Screenshot of emojis in text mode](images/screenshot_emoji_text.png) |
|---------------------------------------------------------------------|--------------------------------------------------------------|
| Emojis in speech mode                                                                   | Emojis in text mode                      |

## Run

If you follow the ACE Agent documentation to run or write your own bots, a bot web UI is automatically started and is available at `http://<YOUR_IP>:7006`. By default, the UI doesn't run with SSL, which blocks speech features (microphone). The workaround is to enable the "Insecure origins treated as secure" flag in `chrome://flags` or `edge://flags`, and add `http://<YOUR_IP>:7006`.

You can also run the UI separately. This is useful if you want to work on the UI code. Instructions on how to run the UI are available in the [docker-compose.yml](./docker-compose.yml) file.

## Developer guide

This section is for developers who wish to understand how the app is built and work on its code.

### Architecture

The web app is composed of two main components: a web client and a server. When the web client is initialized, it establishes a websocket connection with the server. The server interacts with ACE Agent through its gRPC, HTTP or event (Redis) APIs.

![High-level diagram of the architecture of the UI](./images/architecture_high_level.png)

#### Client

The web client is a React web application. It is built statically using ViteJS, and runs entirely in the browser. Its main responsibilities are described below.

##### Managing communications with the server

All interactions between the client and the server go through the same websocket. Whenever a message is received through the websocket (for example: the bot sends a text message), the client updates the application’s state. Similarly, when the user does something (e.g. send a new message), this information is sent to the server through the websocket.

For more details, see:

1. The `useServerState()` custom React hook, which manages the websocket’s state, the messages going through it, and provides APIs for the client to interact with the server.
2. The `UserChatMessage` and BotChatMessage` interface definitions, which describe the payloads sent and received from the server.

##### Managing interaction modes (“speech” vs. “text”)

By default, the app is set in `text` mode, which allows the user to have written conversations with the bot. If the bot supports speech conversations, the UI shows the option to toggle between `text` and `speech` mode.

When the user toggles `speech` mode, the UI shows a simplified conversation history (last two messages), along with a button to start/stop the user’s microphone. It also shows a “pulse” animation when the bot or the user speaks.

Finally, it shows the real-time text transcription of what the user is speaking.

##### Managing multiple bots

In some cases, ACE Agent may run multiple bots at the same time. Currently, this is only supported when using the HTTP interface, which only supports the `text` interaction mode. When this happens, the UI shows a toggle allowing the user to select which bot to interact with. When the user toggles between bots, the conversation history is updated to show the conversation history with the current bot.

###### Recording and sending the user’s audio

![A diagram outlying the flow of audio data](./images/architecture_audio.png)

When `speech` mode is selected by the user, the UI requests access to the user’s microphone. When access is granted, it starts recording chunks of audio that are immediately sent to the server through the websocket connection. The user can choose to disable their microphone.

For more details, see:

1. The `useMicrophone()` custom React hook, which handles microphone access and recording APIs.
2. The `LinearPCMProcessor` class, an audio processing worklet that converts the user’s raw audio data to Linear PCM format, which is the format expected by the server.
3. The `<UserSpeechInput />` component, which displays the UI aspects of audio recording (button, pulse animation, loading states).

##### Playing the bot’s speech responses

![A diagram of the bot audio flow](./images/architecture_bot_audio.png)

In `speech` mode, the UI receives audio chunks from the bot. The chunks are immediately played in the browser as they come.

For more details, see the `useAudioPlayer()` custom React hook, which handles the audio buffer and converts the received audio into a browser-compatible one.

##### Render the conversation history

In `text` mode, this is the list of text messages typed and sent by the user, as well as the bot’s text responses. In `speech` mode, this is the list of audio transcripts (“ASR”) from the user.

For more details, see the `<ConversationHistory />` component.

#### Server

In essence, the server is a proxy between the web client and ACE agent. It manages the websocket connection with the client, forwards user actions (e.g. send a message) to ACE Agent, and forwards ACE agent actions (e.g. the bot sends a message) to the web client.

The main responsibility of the server is to manage API calls to ACE Agent.

ACE Agent supports multiple communication protocols (“interfaces”). These protocols do not all support the same features, and some protocols may be used simultaneously. For example, when running in `event` mode, ACE Agent sends and receives messages through a Redis stream, but also exposes a gRPC API to stream audio.

Furthermore, some ACE Agent APIs are only needed in certain interaction modes (`speech` or `text`). For example, there is no need to use ACE Agent’s `receiveAudio` gRPC API when the user doesn’t use the `speech` interaction mode.

For these reasons, the server defines the concept of *tasks*, which allow the server to handle multiple protocols in parallel, and connect to their APIs only when needed.

##### Tasks

![A diagram explaining how tasks extend a base AbstractTask and how they interact with the client](images/tasks.png)

A *task* implements a specific aspect of the application, and manages the necessary API calls. A task defines a set of `interactionModes` (`text`, `speech`, or both) for which it must run, as well as the ACE Agent interface it’s designed to interact with. It implements `start()` and `stop()` methods.

When a client connects to the server, a new `ChatSession` object is created. The `ChatSession` checks which ACE Agent interfaces are available, and creates a list of all tasks that are compatible with these interfaces. It then immediately checks which tasks are meant to run in the user’s selected interaction mode (by default: `text` mode), and starts them.

If the user toggles `speech` mode, the `ChatSession` stops all `text` tasks, and starts all `speech` tasks.

Finally, when the user leaves the app, the `ChatSession` stops all tasks and cleans them up.

**Example task: GRPCSpeechTask**

![An interaction diagram describing how to GRPCSpeechTask works](./images/example_task.png)

For example, the `GRPCSpeechTask` is responsible for sending and receiving speech from ACE Agent. As its name suggests, it is only instantiated when ACE Agent exposes a gRPC interface (`speech` mode).

Because the task is only needed when the user uses `speech` mode, it defines its `interactionModes` as `[speech]`. As such, the `ChatSession` will only start this task when the user toggles `speech` mode from the UI.

When started, the task’s implementation creates two gRPC streams, sendAudio and receiveAudio. It continuously listens for audio chunks sent by the user, and sends them to ACE Agent via the sendAudio stream. Similarly, it continuously listens for audio chunks sent by ACE Agent through receiveAudio, and sends them to the user.

When the user toggles back to the text interaction mode, the ChatSession stops GRPCSpeechTask, which effectively interrupts the gRPC streams.

##### Communication between tasks

Tasks are designed to run independently, without knowledge of other tasks. This is to reduce coupling between tasks, which helps testing and maintainability.

To communicate, all tasks belonging to a specific `ChatSession` share a common `eventBus`, which is a simple pub-sub system. Tasks can emit events, and subscribe to events.

For example, consider the `WebsocketTask` and the `UMIMTask`. The `WebsocketTask` is responsible for handling communications with the client. The `UMIMTask` is responsible for handling communications with ACE Agent’s event interface. When the bot sends a new message, it is received by the `UMIMTask`, which in turn emits the message’s content through the shared `eventBus`:

```js
// In UMIMTask
private handleRedisEvent(message) {
  switch (message.type) {
    case "StartUtteranceBotAction": {
this.eventBus.emit("botStartedUtterance", message.script);
      break;
      ...
    }
  }
}
```

The `WebsocketTask` can subscribe to this event and decide how to handle it:

```js
// In WebsocketTask
private async listenBotStartedUtterance() {
  while (this.isRunning()) {
    const [text] = await once(
      this.eventBus,
      "botStartedUtterance",
    );
    this.sendMessageToUser(text); // send to websocket
  }
}
```

The advantage of this event-based architecture is that tasks don’t need to know which task emitted the event. For example, if ACE Agent was configured to use its `HTTP` interface instead of the Redis interface, the `HTTPChatTask` would run instead of the `UMIMTask`. As long as the `HTTPChatTask` emits the same `botStartedUtterance` event when the bot sends a message, the `WebsocketTask` will send the message to the user without requiring any changes.

##### Adding new tasks

If you need to implement a feature that is not supported by existing tasks, you can define a new task. Your task must extend the `AbstractTask` base class, and implement the following methods and fields:

1. `start()`: this method should run the core logic of the task (for example, continuously listen for new messages on a `gRPC` client).
2. `interactionModes`: which interaction modes are supported by the task (`text`, `speech` or both). The `ChatSession` will automatically `start()` and `stop()` tasks depending on the user’s chosen interaction mode.
3. `cleanup()`: (optional) if your task needs to run some clean up logic when the user closes the session, it can extend this method to run it. By default, this method does nothing.

Additionally, you should ensure that the task’s core logic is interrupted when the base class’ `abortController` is called. This ensures that the task doesn’t keep running once it’s stopped. An `AbortController` is a native JavaScript API allowing to interrupt asynchronous work. It is compatible with many NodeJS APIs. For example, all gRPC calls accept an optional `signal` parameter:

```js
const metaDataResponse = this.gRPCClient.streamSpeechResults(request, {
  signal: this.abortController.signal,
});
```

Once implemented, the task can be added in `ChatSession`’s `initTasks()` method. From there, the `ChatSession` will automatically `start()` and `stop()` the task based on the user’s chosen interaction mode (`speech` or `text`).

##### Clients

As of today, the server supports three protocols to communicate with ACE Agent:

1. `RedisClient` - to interact with ACE Agent through its event mode
2. `GRPCClient` - to interact with ACE Agent through its speech mode
3. `HTTPClient` - to interact with ACE Agent through its server mode

These clients are located in the `server/clients/` directory and implemented as singletons which can be used from anywhere in the server code:

```js

if (GRPCClient.isAvailable()) {
  const client = GRPCClient.get();
  const metaDataResponse = this.gRPCClient.streamSpeechResults(request);
}
```

The clients can be configured through environment variables. By default, these environment variables use ACE Agent’s default IP and ports:

```sh
# The Redis URL is used when ACE Agent is running in "event" (aka "umim") mode
REDIS_URL=redis://localhost:6379

# The gRPC URL is used when ACE Agent is running in gRPC mode and/or speech mode
GRPC_URL=http://localhost:50055

# The HTTP URL is used when ACE Agent is running in "server" (aka "http") mode
HTTP_CHAT_URL=http://localhost:9000
```

##### Adding new clients

If you would like to extend the Bot Web UI to interact with protocols that are not yet supported, you can create a new client. The client should be located in its own file, in the `server/clients` directory. It should provide a `isAvailable()` method, and a `get()` method.

##### Logging

The server uses `bunyan` for logging. The logger is defined in `server/logger.ts` and can be used from anywhere in the server code. It uses the common logging levels (`debug`, `info`, `warn`, etc) and `sprintf` syntaxes:

```js
import getLogger from "../logger";
const logger = getLogger(<file name>);
logger.info("Person %s said %s!", person.name, message);
```

By default, production and development logs go to `stdout`. In automated tests, only logs of level `ERROR` and above appear in the console.

### Automated tests

#### Running tests

Currently, unit and integration tests are only supported on the server. To run tests, install yarn and run:

```sh
cd ./server
yarn install
yarn test
```

Note: if running yarn install yields the following error:

```sh
YN0001: │ Error: EACCES: permission denied, unlink '/home/<username>/src/bot-maker/bot-web-ui/server/node_modules/.bin/acorn'
```

Run sudo `rm -rf node_modules` and try again.

#### Writing tests

Tests uses node's native test runner, and tsx for typescript support. To write a test, create a file with extension `.test.ts`. As a convention, the test file should:

1. Be in the same directory as the file being tested
2. Have the same name as the file being tested

For example:

```sh
server/emoji-finder/index.ts
server/emoji-finder/index.test.ts
```
