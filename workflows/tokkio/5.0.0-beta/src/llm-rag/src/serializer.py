# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

import json
from loguru import logger
from pipecat.frames.frames import (
    Frame,
    BotStoppedSpeakingFrame,
    UserStoppedSpeakingFrame,
    StartInterruptionFrame,
)
from pipecat.serializers.base_serializer import (
    FrameSerializer,
    FrameSerializerType,
)

from nvidia_pipecat.frames.transcripts import (
    UserUpdatedSpeakingTranscriptFrame,
    UserStoppedSpeakingTranscriptFrame,
    BotUpdatedSpeakingTranscriptFrame,
)
from nvidia_pipecat.frames.action import (
    StartedPresenceUserActionFrame,
    FinishedPresenceUserActionFrame,
)
from nvidia_pipecat.frames.nvidia_rag import NvidiaRAGSettingsFrame

from nvidia_pipecat.frames.custom_view import (
    StartCustomViewFrame,
    StopCustomViewFrame,
)

class TokkioUIWebSocketSerializer(FrameSerializer):
    @property
    def type(self) -> FrameSerializerType:
        return FrameSerializerType.TEXT

    async def serialize(self, frame: Frame) -> str | bytes | None:
        if isinstance(frame, StartedPresenceUserActionFrame):
            logger.info("Notified user of presence start")
            message = {"type": "user_presence_start"}
            return json.dumps(message)
        if isinstance(frame, FinishedPresenceUserActionFrame):
            logger.info("Notified user of presence end")
            message = {"type": "user_presence_end"}
            return json.dumps(message)
        if isinstance(frame, BotUpdatedSpeakingTranscriptFrame):
            logger.info(f"Notified user of TTS update. TTS transcript was: \"{frame.transcript}\"")
            message = {"type": "tts_update", "tts": frame.transcript}
            return json.dumps(message)
        if isinstance(frame, BotStoppedSpeakingFrame):
            logger.info("Notified user of TTS end")
            message = {"type": "tts_end"}
            return json.dumps(message)
        if isinstance(frame, UserUpdatedSpeakingTranscriptFrame):
            logger.info(f"Notified user of ASR update. Interim ASR transcript was: \"{frame.transcript}\"")
            message = {"type": "asr_update", "asr": frame.transcript}
            return json.dumps(message)
        if isinstance(frame, UserStoppedSpeakingTranscriptFrame):
            logger.info(f"Notified user of ASR end. Final ASR transcript was: \"{frame.transcript}\"")
            message = {"type": "asr_end", "asr": frame.transcript}
            return json.dumps(message)
        if isinstance(frame, StartCustomViewFrame):
            logger.info("Notified user of custom view start")
            message = {
                "type": "custom_view",
                **json.loads(frame.to_json()),
                "show_ui": True,
            }
            return json.dumps(message)
        if isinstance(frame, StopCustomViewFrame):
            logger.info("Notified user of custom view end")
            message = {
                "type": "custom_view",
                "show_ui": False,
            }
            return json.dumps(message)
        if isinstance(frame, StartInterruptionFrame):
            message = {
                "type": "interruption",
            }
            return json.dumps(message)
        return None

    async def deserialize(self, data: str | bytes) -> Frame | None:
        try:
            message = json.loads(data)
        except json.decoder.JSONDecodeError:
            return None

        if "type" in message:
            match message.get("type"):
                case "conversation_start":
                    return StartedPresenceUserActionFrame(action_id="")
                case "conversation_end":
                    return FinishedPresenceUserActionFrame(action_id="")
                case "rag_settings":
                    return NvidiaRAGSettingsFrame(settings={"collection_name":message.get("collection_name", None), "use_knowledge_base":message.get("use_knowledge_base", None), "rag_server_url":message.get("rag_server_url", None)})
                case _:
                    pass
        return None
