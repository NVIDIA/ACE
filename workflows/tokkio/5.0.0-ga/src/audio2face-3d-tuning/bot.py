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

import os
from dotenv import load_dotenv, find_dotenv, dotenv_values
import uvicorn
from fastapi import FastAPI
from loguru import logger

from src.serializer import TokkioUIWebSocketSerializer
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.task import PipelineParams, PipelineTask
from nvidia_pipecat.utils.message_broker import MessageBrokerConfig
from nvidia_pipecat.transports.network.ace_fastapi_websocket import (
    ACETransport,
    ACETransportParams,
)
from nvidia_pipecat.transports.services.ace_controller.routers.websocket_router import (
    router as websocket_router,
)
from nvidia_pipecat.transports.services.ace_controller.routers.register_apis_router import (
    router as register_apis_router,
)
from nvidia_pipecat.pipeline.ace_pipeline_runner import (
    PipelineMetadata,
    ACEPipelineRunner,
)
from nvidia_pipecat.services.elevenlabs import ElevenLabsTTSServiceWithEndOfSpeech
from nvidia_pipecat.services.animation_graph_service import (
    AnimationGraphService,
    AnimationGraphConfiguration,
)
from nvidia_pipecat.services.audio2face_3d_service import Audio2Face3DService
from nvidia_pipecat.utils.logging import setup_default_ace_logging

from .tuningtools import *

# Inline animation configuration
animation_config = AnimationGraphConfiguration(
    animation_types={
        "gesture": {
            "duration_relevant_animation_name": "gesture",
            "animations": {
                "gesture": {
                    "default_clip_id": "none",
                    "clips": [
                        {
                            "clip_id": "Goodbye",
                            "description": "Waving goodbye: Waves with left hand extended high.",
                            "duration": 2,
                            "meaning": "Taking leave of someone from a further distance, or getting someone's attention."
                        },
                        {
                            "clip_id": "Welcome",
                            "description": "Waving hello: Spreads arms slightly, then raises right hand next to face and waves with an open hand.",
                            "duration": 2.5,
                            "meaning": "Greeting someone in a shy or cute manner, showing a positive and non-threatening attitude."
                        }
                    ]
                }
            }
        },
        "posture": {
            "duration_relevant_animation_name": "posture",
            "animations": {
                "posture": {
                    "default_clip_id": "Attentive",
                    "clips": [
                        {
                            "clip_id": "Talking",
                            "description": "Small gestures with hand and upper body: Avatar is talking",
                            "duration": -1,
                            "meaning": "Emphasizing that Avatar is talking"
                        },
                        {
                            "clip_id": "Listening",
                            "description": "Small gestures with hand and upper body: Avatar is listening",
                            "duration": -1,
                            "meaning": "Emphasizing that one is listening"
                        }
                    ]
                }
            }
        },
        "facial_gesture": {
            "duration_relevant_animation_name": "facial_gesture",
            "animations": {
                "facial_gesture": {
                    "default_clip_id": "none",
                    "clips": [
                        {
                            "clip_id": "Angry",
                            "description": "Angry: Furrowed brow, short glare at the user with an angry frown.",
                            "duration": 1.7,
                            "meaning": "Expression of anger, being displeased, insulted or bitter."
                        },
                        {
                            "clip_id": "Angry_Intense",
                            "description": "Very Angry: Furrowed brow, lowering head, angrily showing teeth.",
                            "duration": 2.3,
                            "meaning": "Expression of rage or hatred, being spiteful or adversarial."
                        }
                    ]
                }
            }
        },
        "position": {
            "duration_relevant_animation_name": "position",
            "animations": {
                "position": {
                    "default_clip_id": "Center",
                    "clips": [
                        {
                            "clip_id": "Left",
                            "description": "Bot positions itself to the left of the scene",
                            "duration": -1,
                            "meaning": "move to the left"
                        },
                        {
                            "clip_id": "Right",
                            "description": "Bot positions itself to the right of the scene",
                            "duration": -1,
                            "meaning": "move to the right"
                        },
                        {
                            "clip_id": "Center",
                            "description": "Bot positions itself at the center of the scene",
                            "duration": -1,
                            "meaning": "move to the center"
                        }
                    ]
                }
            }
        }
    }
)

load_dotenv(override=True)

dotenv_path = find_dotenv()
if dotenv_path:
    logger.info(f"Found .env file at: {dotenv_path}")
    for env_name, env_value in dotenv_values(dotenv_path).items():
        logger.info(f"{env_name}={env_value}")

setup_default_ace_logging(level="DEBUG")

logger.debug("started loading animation database")
AnimationGraphService.pregenerate_animation_databases(animation_config)
logger.debug("completed loading animation database")

async def create_pipeline_task(pipeline_metadata: PipelineMetadata):
    transport = ACETransport(
        websocket=pipeline_metadata.websocket,
        params=ACETransportParams(
            serializer=TokkioUIWebSocketSerializer(),
            rtsp_url=pipeline_metadata.rtsp_url,
        ),
    )
    tuning_input_transport = TuningInputTransport(app, pipeline_metadata.stream_id)
    tuning_output_transport = TuningOutputTransport(app, pipeline_metadata.stream_id)

    a2f = Audio2Face3DService(
        target=os.getenv("A2F_GRPC_URL", "0.0.0.0:50010"),
        sample_rate=16000,
        bit_per_sample=16,
    )

    animgraph = AnimationGraphService(
        animation_graph_rest_url=os.getenv("ANIMGRAPH_URL", "http://localhost:8020"),
        animation_graph_grpc_target=os.getenv("ANIMGRAPH_GRPC_URL", "ia-animation-graph-microservice:51000"),
        message_broker_config=MessageBrokerConfig(
            "redis", os.getenv("REDIS_URL", "redis://localhost:6379")
        ),
        config=animation_config,
    )

    tts = ElevenLabsTTSServiceWithEndOfSpeech(
        api_key=os.getenv("ELEVENLABS_API_KEY"),
        voice_id=os.getenv("ELEVENLABS_VOICE_ID", "cgSgspJ2msm6clMCkdW9"),
        sample_rate=16000,
        model = "eleven_flash_v2_5",
        stability = 0.3,
        speed = 0.97,
        similarity_boost = 0.85
    )

    tts_cache = NvidiaTTSAudioCacher()
    pipeline = Pipeline(
        [
            transport.input(),
            tuning_input_transport,
            tts,
            tts_cache,
            a2f,
            animgraph,
            tuning_output_transport,
            transport.output(),  # Websocket output to client
        ]
    )

    task = PipelineTask(
        pipeline,
        params=PipelineParams(
            allow_interruptions=True,
            enable_metrics=True,
            enable_usage_metrics=True,
            start_metadata={"stream_id" : pipeline_metadata.stream_id},
        ),
    )

    return task


app = FastAPI()
app.include_router(websocket_router)
app.include_router(register_apis_router)
app.include_router(a2f_3d_tuning_router)
runner = ACEPipelineRunner(pipeline_callback=create_pipeline_task, enable_rtsp=True)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
