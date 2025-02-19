# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any

FALLBACK_RESPONSE = "Sorry, I could not find an answer online."


class ChatRequest(BaseModel):
    Query: Optional[str] = Field(default="", description="The user query which needs to be processed.")
    UserId: str = Field(
        description="Mandatory unique identifier to recognize which user is interacting with the Chat Engine."
    )


class EventRequest(BaseModel):
    EventType: str = Field(default="", description="The event name which needs to be processed.")
    UserId: str = Field(
        description="Mandatory unique identifier to recognize which user is interacting with the Chat Engine."
    )


class ResponseField(BaseModel):
    Text: str = Field(
        default="",
        description="Text response to be sent out. This field will also be picked by a Text to Speech Synthesis module if enabled for speech based bots.",
    )
    CleanedText: str = Field(
        default="", description="Text response from the Chat Engine with all SSML/HTML tags removed."
    )
    NeedUserResponse: Optional[bool] = Field(
        default=True,
        description="This field can be used by end user applications to deduce if user response is needed or not for a dialog initiated query. This is set to true automatically if form filling is active and one or more slots are missing.",
    )
    IsFinal: bool = Field(
        default=False,
        description="This field to indicate the final response chunk when streaming. The chunk with IsFinal=true will contain the full Chat Engine response attributes.",
    )


class ChatResponse(BaseModel):
    UserId: str = Field(
        default="",
        description="Unique identifier to recognize which user is interacting with the Chat Engine. This is populated from the request JSON.",
    )
    QueryId: str = Field(
        default="",
        description="Unique identifier for the user query assigned automatically by the Chat Engine unless specified in request JSON.",
    )
    Response: ResponseField = Field(
        default=ResponseField(),
        description="Final response template from the Chat Engine. This field can be picked up from domain rule files or can be formulated directly from custom fulfillment modules.",
    )
    Metadata: Optional[Dict[str, Any]] = Field(
        default={"SessionId": "", "StreamId": ""},
        description="Any additional information related to the request.",
    )


class EventResponse(BaseModel):
    UserId: str = Field(
        default="",
        description="Unique identifier to recognize which user is interacting with the Chat Engine. This is populated from the request JSON.",
    )
    Events: List[Dict[str, Any]] = Field(
        default=[], description="The generated event list for the provided EventType from Chat Engine."
    )
    Response: ResponseField = Field(
        default=ResponseField(),
        description="Final response template from the Chat Engine. This field can be picked up from domain rule files or can be formulated directly from custom fulfillment modules.",
    )
