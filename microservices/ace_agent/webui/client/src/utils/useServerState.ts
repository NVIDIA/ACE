
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

import { useEffect, useReducer, useRef } from "react";

import {
  AuthorType,
  type BotChatMessage,
  type UserChatMessage,
  ChatMessageContentType,
  MessageID,
  BotChatTextMessage,
  BotChatEmojiMessage,
  UserChatTextMessage,
  SystemConfigMessage,
  UserChatToggleSpeechMessage,
  InteractionMode,
  ServerConfig,
  SystemMessageContent,
  ChatMessageTextContent,
} from "../../../shared/types";

interface ServerState {
  messages: (BotChatMessage | UserChatMessage)[];
  isBotTyping: boolean;
  latestBotEmoji: string | null;
  serverConfig: ServerConfig | null;
  botList: string[];
  connectionState: ConnectionState;
}

enum ServerStateActionType {
  CONNECTION_LOADING = "CONNECTION_LOADING",
  RECEIVED_BOT_TEXT_MESSAGE = "RECEIVED_BOT_TEXT_MESSAGE",
  RECEIVED_ASR = "RECEIVED_ASR",
  RECEIVED_BOT_EMOJI = "RECEIVED_BOT_EMOJI",
  RECEIVED_BOT_IS_TYPING = "RECEIVED_BOT_IS_TYPING",
  CONNECTION_READY = "CONNECTION_READY",
  CONNECTION_ERROR = "CONNECTION_ERROR",
  CONNECTION_CLOSED = "CONNECTION_CLOSED",
  SENT_USER_CHAT_MESSAGE = "SENT_USER_CHAT_MESSAGE",
  RECEIVED_SYSTEM_CONFIG_CHANGE = "RECEIVED_SYSTEM_CONFIG_CHANGE",
  RECEIVED_BOT_LIST = "RECEIVED_BOT_LIST",
}

export enum ConnectionState {
  INITIAL = "INITIAL",
  READY = "READY",
  ERROR = "ERROR",
  CLOSED = "CLOSED",
}

interface ServerStateActionConnectionLoading {
  type: ServerStateActionType.CONNECTION_LOADING;
}

interface ServerStateActionReceivedServerPush {
  type: ServerStateActionType.RECEIVED_BOT_TEXT_MESSAGE;
  payload: BotChatTextMessage;
}

interface ServerStateActionReceivedASR {
  type: ServerStateActionType.RECEIVED_ASR;
  payload: {
    text: string;
    messageID: string;
  };
}

interface ServerStateActionReceivedBotEmoji {
  type: ServerStateActionType.RECEIVED_BOT_EMOJI;
  payload: BotChatEmojiMessage;
  emoji: string;
}

interface ServerStateActionReceivedBotIsTyping {
  type: ServerStateActionType.RECEIVED_BOT_IS_TYPING;
}

interface ServerStateActionConnectionReady {
  type: ServerStateActionType.CONNECTION_READY;
}

interface ServerStateActionConnectionError {
  type: ServerStateActionType.CONNECTION_ERROR;
  payload: Error;
}

interface ServerStateActionConnectionClosed {
  type: ServerStateActionType.CONNECTION_CLOSED;
  payload: string;
}

interface ServerStateActionSentChatMessage {
  type: ServerStateActionType.SENT_USER_CHAT_MESSAGE;
  payload: UserChatTextMessage;
}

interface ServerStateActionReceivedSystemMessageMessage {
  type: ServerStateActionType.RECEIVED_SYSTEM_CONFIG_CHANGE;
  payload: ServerConfig;
}

interface ServerStateActionReceivedBotList {
  type: ServerStateActionType.RECEIVED_BOT_LIST;
  payload: string[];
}

type ServerStateAction =
  | ServerStateActionConnectionLoading
  | ServerStateActionReceivedServerPush
  | ServerStateActionReceivedASR
  | ServerStateActionReceivedBotEmoji
  | ServerStateActionReceivedBotIsTyping
  | ServerStateActionConnectionReady
  | ServerStateActionConnectionError
  | ServerStateActionConnectionClosed
  | ServerStateActionSentChatMessage
  | ServerStateActionReceivedSystemMessageMessage
  | ServerStateActionReceivedBotList;

function reducer(state: ServerState, action: ServerStateAction): ServerState {
  switch (action.type) {
    case ServerStateActionType.CONNECTION_LOADING:
      return { ...state, connectionState: ConnectionState.INITIAL };
    case ServerStateActionType.CONNECTION_READY:
      return { ...state, connectionState: ConnectionState.READY };
    case ServerStateActionType.CONNECTION_ERROR:
      return { ...state, connectionState: ConnectionState.ERROR };
    case ServerStateActionType.CONNECTION_CLOSED:
      return { ...state, connectionState: ConnectionState.CLOSED };
    case ServerStateActionType.RECEIVED_BOT_TEXT_MESSAGE:
      return {
        ...state,
        messages: [...state.messages, action.payload],
        isBotTyping: false,
      };
    case ServerStateActionType.RECEIVED_BOT_EMOJI:
      return {
        ...state,
        messages: [...state.messages, action.payload],
        latestBotEmoji: action.payload.content.emoji,
        isBotTyping: false,
      };
    case ServerStateActionType.RECEIVED_BOT_IS_TYPING:
      return {
        ...state,
        isBotTyping: true,
      };
    case ServerStateActionType.RECEIVED_ASR:
      // When receiving ASR data, check if a message with the message ID has
      // already been created. If it exists, update it directly. Otherwise,
      // create a new message
      const payload = action.payload;
      const message = state.messages.find(
        (message) =>
          message.author === AuthorType.USER &&
          message.content.type === ChatMessageContentType.TEXT &&
          message.content.messageID === payload.messageID
      ) as UserChatMessage | undefined;

      // MessageID matches an existing ID, update it in-line
      if (message) {
        (message.content as ChatMessageTextContent).text = payload.text;
        return state;
      }

      // MessageID doesn't match an existing message, create a new message
      return {
        ...state,
        messages: [
          ...state.messages,
          {
            author: AuthorType.USER,
            content: {
              type: ChatMessageContentType.TEXT,
              messageID: payload.messageID,
              text: payload.text,
              botName: null,
            },
          },
        ],
      };
    case ServerStateActionType.SENT_USER_CHAT_MESSAGE:
      return {
        ...state,
        messages: [...state.messages, action.payload],
      };
    case ServerStateActionType.RECEIVED_SYSTEM_CONFIG_CHANGE:
      return {
        ...state,
        serverConfig: action.payload,
      };
    case ServerStateActionType.RECEIVED_BOT_LIST:
      return {
        ...state,
        botList: action.payload,
      };
    default:
      return state;
  }
}

const INITIAL_STATE: ServerState = {
  messages: [],
  connectionState: ConnectionState.INITIAL,
  isBotTyping: false,
  latestBotEmoji: "🙂",
  serverConfig: null,
  botList: [],
};

function getServerPort() {
  // In production, the port for the webserver is only known at startup time. Since the
  // web app is built statically, it cannot rely on import.meta.env.VITE_SERVER_PORT to
  // get the webserver's port, because this variable is populated at build time.
  // Instead, a process.env.VITE_SERVER_PORT variable is dynamically injected into the
  // webpage when it's run in production.

  const DEFAULT_SERVER_PORT = 7007;

  if (import.meta.env.PROD) {
    return window.process?.env?.VITE_SERVER_PORT || DEFAULT_SERVER_PORT;
  }

  return import.meta.env.VITE_SERVER_PORT || DEFAULT_SERVER_PORT;
}

function createWebSocket(
  dispatch: React.Dispatch<ServerStateAction>,
  onReceiveBotAudio: (chunk: Int16Array) => void,
  onSystemShutdown: (reason: string) => void,
  onWebSocketError: (e: Error) => void,
  onUserBargeIn: () => void
): WebSocket {
  const hostname = location.hostname;
  const serverPort = getServerPort();
  const serverProtocol =
    window.location.protocol === "https:" ? "wss://" : "ws://";
  const webSocketURL = `${serverProtocol}${hostname}:${serverPort}`;
  const socket = new WebSocket(webSocketURL);
  dispatch({
    type: ServerStateActionType.CONNECTION_LOADING,
  });

  socket.addEventListener("open", () => {
    dispatch({ type: ServerStateActionType.CONNECTION_READY });
  });
  socket.addEventListener("error", () =>
    onWebSocketError(
      new Error(
        `Error establishing a connection with the web server at ${webSocketURL}. Is the server running, and are you forwarding port ${serverPort}?`
      )
    )
  );

  socket.addEventListener("message", (event) => {
    if (event.data instanceof ArrayBuffer) {
      onReceiveBotAudio(new Int16Array(event.data));
      return;
    }
    const message = JSON.parse(event.data) as
      | BotChatMessage
      | SystemConfigMessage;
    if (message.author === AuthorType.SYSTEM) {
      if (message.content.type === SystemMessageContent.CONFIG_CHANGE) {
        dispatch({
          type: ServerStateActionType.RECEIVED_SYSTEM_CONFIG_CHANGE,
          payload: message.content,
        });
      }
      if (message.content.type === SystemMessageContent.SHUTDOWN) {
        onSystemShutdown(message.content.reason);
      }
      return;
    }
    if (message.content.type === ChatMessageContentType.ASR) {
      const asr = message.content;
      dispatch({
        type: ServerStateActionType.RECEIVED_ASR,
        payload: {
          text: asr.transcript,
          messageID: asr.messageID,
        },
      });
      return;
    }
    if (message.content.type === ChatMessageContentType.EMOJI) {
      dispatch({
        type: ServerStateActionType.RECEIVED_BOT_EMOJI,
        payload: message as BotChatEmojiMessage,
        emoji: message.content.emoji,
      });
      return;
    }
    if (message.content.type === ChatMessageContentType.TYPING) {
      dispatch({
        type: ServerStateActionType.RECEIVED_BOT_IS_TYPING,
      });
      return;
    }
    if (message.content.type === ChatMessageContentType.BOT_LIST) {
      dispatch({
        type: ServerStateActionType.RECEIVED_BOT_LIST,
        payload: message.content.botList,
      });
      return;
    }
    if (message.content.type === ChatMessageContentType.USER_BARGE_IN) {
      onUserBargeIn();
      return;
    }

    dispatch({
      type: ServerStateActionType.RECEIVED_BOT_TEXT_MESSAGE,
      payload: message as BotChatTextMessage,
    });
  });

  socket.addEventListener("error", (event) => {
    dispatch({
      type: ServerStateActionType.CONNECTION_ERROR,
      payload: new Error(event.type),
    });
  });

  socket.addEventListener("close", (event) => {
    if (event.code === 1000) {
      dispatch({
        type: ServerStateActionType.CONNECTION_CLOSED,
        payload: event.reason,
      });
    } else {
      dispatch({
        type: ServerStateActionType.CONNECTION_ERROR,
        payload: new Error(event.reason),
      });
    }
  });

  window.addEventListener("beforeunload", () => {
    socket.close();
  });

  return socket;
}

export default function useServerState(
  onReceiveBotAudio: (chunk: Int16Array) => void,
  onSystemShutdown: (reason: string) => void,
  onWebsocketError: (e: Error) => void,
  onUserBargeIn: () => void
): {
  serverState: ServerState;
  sendChatMessage: (
    messageID: MessageID,
    content: string,
    botName: string | null
  ) => void;
  sendUserTyping: (
    messageID: string,
    text: string,
    isNewMessage: boolean
  ) => void;
  sendUserAudio: (buffer: ArrayBuffer) => void;
  toggleSpeech: (interactionMode: InteractionMode) => void;
} {
  const [serverState, dispatch] = useReducer(reducer, INITIAL_STATE);

  const socketRef = useRef<WebSocket>();

  useEffect(() => {
    const socket = createWebSocket(
      dispatch,
      onReceiveBotAudio,
      onSystemShutdown,
      onWebsocketError,
      onUserBargeIn
    );
    socketRef.current = socket;
    socket.binaryType = "arraybuffer";

    return () => socket.close(1000);
  }, []);

  function sendChatMessage(
    messageID: MessageID,
    text: string,
    botName: string | null
  ): void {
    const message: UserChatTextMessage = {
      author: AuthorType.USER,
      content: {
        type: ChatMessageContentType.TEXT,
        messageID,
        text,
        botName,
      },
    };
    socketRef?.current?.send(JSON.stringify(message));
    dispatch({
      type: ServerStateActionType.SENT_USER_CHAT_MESSAGE,
      payload: message,
    });
  }

  function sendUserTyping(
    messageID: MessageID,
    text: string,
    isNewMessage: boolean
  ): void {
    const payload: UserChatMessage = {
      author: AuthorType.USER,
      content: {
        type: ChatMessageContentType.TYPING,
        messageID,
        text,
        isNewMessage,
      },
    };
    socketRef?.current?.send(JSON.stringify(payload));
  }

  function sendUserAudio(buffer: ArrayBuffer): void {
    socketRef?.current?.send(buffer);
  }

  function toggleSpeech(interactionMode: InteractionMode): void {
    const payload: UserChatToggleSpeechMessage = {
      author: AuthorType.USER,
      content: {
        type: ChatMessageContentType.TOGGLE_SPEECH,
        interactionMode,
      },
    };
    socketRef.current?.send(JSON.stringify(payload));
  }

  return {
    serverState,
    sendChatMessage,
    sendUserTyping,
    sendUserAudio,
    toggleSpeech,
  };
}
