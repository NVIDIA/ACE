#!/usr/bin/env python3

# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from dataclasses import dataclass
from typing import Union
from fastapi import FastAPI, APIRouter, HTTPException
from loguru import logger
from pydantic import BaseModel
from pipecat.processors.frame_processor import FrameDirection, FrameProcessor

from pipecat.frames.frames import (
    DataFrame,
    Frame,
    TTSAudioRawFrame,
    TTSStartedFrame,
    TTSStoppedFrame,
    TTSSpeakFrame
)
from nvidia_pipecat.pipeline.ace_pipeline_runner import (
    ACEPipelineRunner,
)

@dataclass
class ReplayCacheFrame(DataFrame):
    """A frame that allows the pipeline to replay audio between start and end times."""

    def __init__(self, start_time: float, end_time: float):
        super().__init__()
        self.start_time = start_time
        self.end_time = end_time


@dataclass
class ClipLengthFrame(DataFrame):
    """A frame that contains the cached clip length."""

    def __init__(self, clip_length_seconds: float):
        super().__init__()
        self.clip_length_seconds = clip_length_seconds


class NvidiaTTSAudioCacher(FrameProcessor):
    """
    Cache the latest TTS response and allows replaying it.
    """

    def __init__(self):
        super().__init__()
        self._cache = []
        self._clip_length_seconds = 0.0

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)
        if isinstance(frame, TTSStartedFrame):
            self._cache = []
            self._clip_length_seconds = 0.0
            await self.push_frame(frame, direction)
        elif isinstance(frame, TTSAudioRawFrame):
            self._cache.append(frame)
            self._clip_length_seconds += len(frame.audio) / frame.sample_rate
            await self.push_frame(frame, direction)
        elif isinstance(frame, TTSStoppedFrame):
            await self.push_frame(frame, direction)
            await self.push_frame(ClipLengthFrame(self._clip_length_seconds))
        elif isinstance(frame, ReplayCacheFrame):
            await self.replay_cache(frame.start_time, frame.end_time)
        else:
            await self.push_frame(frame, direction)

    def _find_frame_index(self, target_time: float) -> tuple[int, float, float, float]:
        current_time = 0.0
        target_time_offset = 0.0
        frame_idx = len(self._cache) - 1

        for i, frame in enumerate(self._cache):
            frame_duration = len(frame.audio) / frame.sample_rate
            if current_time + frame_duration > target_time:
                target_time_offset = target_time - current_time
                frame_idx = i
                break
            current_time += frame_duration
            target_time_offset = frame_duration
        return frame_idx, round(target_time_offset, 1)

    def _trim_audio_frame(self, frame: TTSAudioRawFrame, start_offset: float, end_offset: float) -> TTSAudioRawFrame:
        """
        Trim a TTSAudioRawFrame to only include audio between start and end offsets in seconds.
        """
        start_samples = int(start_offset * frame.sample_rate)
        if end_offset == -1:
            end_samples = len(frame.audio)
        else:
            end_samples = min(len(frame.audio), int(end_offset * frame.sample_rate) + 1)

        trimmed_audio = frame.audio[start_samples:end_samples]
        return TTSAudioRawFrame(
            audio=trimmed_audio,
            sample_rate=frame.sample_rate,
            num_channels=frame.num_channels,
        )

    async def replay_cache(self, start_time: float, end_time: float):
        """
        Replay the cached frames.
        """
        if len(self._cache) > 0:
            logger.info(f"Replaying cache from {start_time} to {end_time}")
            # Find start and end frame indices
            start_frame_idx, start_time_offset = self._find_frame_index(start_time)
            end_frame_idx, end_time_offset = self._find_frame_index(end_time)

            # Only push frames between start and end time
            if start_frame_idx < end_frame_idx:
                await self.push_frame(TTSStartedFrame())
                await self.push_frame(self._trim_audio_frame(self._cache[start_frame_idx], start_time_offset, -1))

                for frame in self._cache[start_frame_idx + 1 : end_frame_idx]:
                    await self.push_frame(
                        TTSAudioRawFrame(
                            audio=frame.audio,
                            sample_rate=frame.sample_rate,
                            num_channels=frame.num_channels,
                        )
                    )

                await self.push_frame(self._trim_audio_frame(self._cache[end_frame_idx], 0, end_time_offset))
                await self.push_frame(TTSStoppedFrame())

            elif start_frame_idx == end_frame_idx:
                await self.push_frame(TTSStartedFrame())
                await self.push_frame(self._trim_audio_frame(self._cache[start_frame_idx], start_time, end_time))
                await self.push_frame(TTSStoppedFrame())
        else:
            logger.info("NvidiaTTSResponserCacher is empty, nothing to replay.")


a2f_3d_tuning_router = APIRouter()


@a2f_3d_tuning_router.get("/fetch_stream_ids")
async def fetch_stream_ids():
    """
    Get all active stream IDs.

    Returns:
        dict: A dictionary containing a list of active stream IDs.
    """
    pipeline_runner = ACEPipelineRunner.get_instance()
    # _pipelines is a private variable by convention but we can still access it here.
    # It is safe to do so since we don't modify it.
    stream_ids = list(pipeline_runner._pipelines.keys())
    logger.info(f"Fetched {len(stream_ids)} active stream IDs")
    return {"stream_ids": stream_ids}


class ReplayRequest(BaseModel):
    start_time: float
    end_time: float


class LLMRequest(BaseModel):
    text: str


class TuningInputTransport(FrameProcessor):
    def __init__(self, app: FastAPI, stream_id: str):
        super().__init__()
        self._app = app
        self._stream_id = stream_id
        self._router = APIRouter()
        self._register_routes()

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)
        await self.push_frame(frame, direction)

    def _register_routes(self):
        self._router.add_api_route(f"/tuning-request/{self._stream_id}", self.tuning_request, methods=["POST"])
        self._app.include_router(self._router)

    async def tuning_request(self, request: Union[ReplayRequest, LLMRequest]):
        """
        Handle a tuning request for a specific stream.

        Args:
            request: A request object that can either be a ReplayRequest or LLMRequest.

        Returns:
            dict: Success or error message.
        """
        if isinstance(request, ReplayRequest):
            return await self.handle_replay(request.start_time, request.end_time)
        elif isinstance(request, LLMRequest):
            return await self.inject_llm_response(request.text)
        else:
            raise HTTPException(status_code=400, detail="Invalid request type")

    async def handle_replay(self, start_time: float, end_time: float):
        """
        Handle a replay request for a specific stream.
        """
        await self.push_frame(ReplayCacheFrame(start_time, end_time))

    async def inject_llm_response(self, text: str):
        """
        Handle a LLM request for a specific stream.
        """
        await self.push_frame(TTSSpeakFrame(text))


class TuningOutputTransport(FrameProcessor):
    """Transport for tuning to fetch the clip length and send the result to the client."""

    def __init__(self, app: FastAPI, stream_id: str):
        super().__init__()
        self._app = app
        self._stream_id = stream_id
        self._clip_length_seconds = 0.0
        self._router = APIRouter()
        self._register_routes()

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        """Process ClipLengthFrame and save the clip length."""
        await super().process_frame(frame, direction)
        if isinstance(frame, ClipLengthFrame):
            logger.info(f"Received ClipLengthFrame with clip_length_seconds: {frame.clip_length_seconds}")
            self._clip_length_seconds = frame.clip_length_seconds
        else:
            await self.push_frame(frame, direction)

    def _register_routes(self):
        self._router.add_api_route(f"/clip-length/{self._stream_id}", self.clip_length, methods=["GET"])
        self._app.include_router(self._router)

    async def clip_length(self):
        """
        Handle a clip length request for a specific stream.
        """
        return {"clip_length_seconds": self._clip_length_seconds}
