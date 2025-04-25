# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from typing import List, Literal, Union
from pydantic import BaseModel, Field, root_validator, ValidationError, StrictStr, HttpUrl, StrictBool
import yaml
from nvidia_pipecat.services.animation_graph_service import AnimationGraphConfiguration

# Define individual processors
class Pipeline(BaseModel):
    llm_processor: Literal["NvidiaRAGService", "NvidiaLLMService", "OpenAILLMService"]
    filler: list[str] = [
        "Let me think",
        "Hmmm"
    ]
    time_delay: float = 2.0

class UserPresenceProcessor(BaseModel):
    welcome_message: StrictStr = "Hello"
    farewell_message: StrictStr = "Bye"

class ProactivityProcessor(BaseModel):
    timer_duration: int = 100
    default_message: StrictStr = "I'm here if you need me!"

class OpenAILLMContext(BaseModel):
    name: str
    prompt: str

# This configuration is only used when llm_processor is set to "NvidiaRAGService"
class NvidiaRAGService(BaseModel):
    use_knowledge_base: bool = True
    max_tokens: int = 1000
    rag_server_url: str
    collection_name: StrictStr = "collection_name"
    suffix_prompt: str = ""
    
# This configuration is only used when llm_processor is set to "NvidiaLLMService"
class NvidiaLLMService(BaseModel):
    model: str = "nvdev/meta/llama-3.1-8b-instruct"

# This configuration is only used when llm_processor is set to "OpenAILLMService"
class OpenAILLMService(BaseModel):
    model: str  

class FacialGestureProviderProcessor(BaseModel):
    user_stopped_speaking_gesture: str
    start_interruption_gesture: str
    probability: float = 0.5

class CustomViewProcessor(BaseModel):
    confidence_threshold: float = 0.5
    top_n: int = 2

# Root model for the pipeline configuration
class Config(BaseModel):
    Pipeline: Pipeline
    UserPresenceProcesssor: UserPresenceProcessor
    ProactivityProcessor: ProactivityProcessor
    OpenAILLMContext: OpenAILLMContext
    NvidiaRAGService: NvidiaRAGService
    NvidiaLLMService: NvidiaLLMService
    OpenAILLMService: OpenAILLMService
    FacialGestureProviderProcessor: FacialGestureProviderProcessor
    AnimationGraphService: AnimationGraphConfiguration
    CustomViewProcessor: CustomViewProcessor
