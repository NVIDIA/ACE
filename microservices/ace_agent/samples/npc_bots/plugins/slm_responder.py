#  Copyright(c) 2023 NVIDIA Corporation.All rights reserved.

#  NVIDIA Corporation and its licensors retain all intellectual property
#  and proprietary rights in and to this software, related documentation
#  and any modifications thereto.Any use, reproduction, disclosure or
#  distribution of this software and related documentation without an express
#  license agreement from NVIDIA Corporation is strictly prohibited.

import time
import logging
import os
import sys
import json

from datetime import datetime
from typing import Dict, Optional, Union, List
from openai import AsyncOpenAI
from fastapi import APIRouter, Body, Response, status
from fastapi.responses import StreamingResponse
from parameters import param
from prompt_former import get_prompt
from typing_extensions import Annotated
from traceback import print_exc


sys.path.append(os.path.dirname(__file__))

from schemas import ChatRequest, EventRequest, EventResponse, ChatResponse

logger = logging.getLogger("plugin")
router = APIRouter()


def log(what: str):
    """Log compatible with the nemoguardrails log output to show output as part of logging output"""
    logger.info(f"A Colang debug info: {what}")


nvidia_api_key = os.getenv("NVIDIA_API_KEY")
client = AsyncOpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=nvidia_api_key,
)

prompt = get_prompt()

EVENTS_NOT_REQUIRING_RESPONSE = [
    "system.event_pipeline_acquired",
    "system.event_pipeline_released",
    "system.event_exit",
]
MODEL_NAME = os.getenv("MODEL_NAME", None) or param.get("slm_responder").get(
    "MODEL_NAME", "nvidia/nemotron-mini-4b-instruct"
)

TEMPERATURE = os.getenv("TEMPERATURE", None) or param.get("slm_responder").get("TEMPERATURE", 0.2)
TOP_P = os.getenv("TOP_P", None) or param.get("slm_responder").get("TOP_P", 0.7)
MAX_TOKENS = os.getenv("MAX_TOKENS", None) or param.get("slm_responder").get("MAX_TOKENS", 200)


async def stream(
    question: Optional[str] = "",
    chat_history: Optional[List] = [],
    num_tokens: Optional[int] = MAX_TOKENS,
) -> int:
    async def generator():

        full_response = ""
        if question:
            message = [{"role": "system", "content": prompt}]
            user_query = [{"role": "user", "content": question}]
            message.extend(chat_history)
            message.extend(user_query)
            async with await client.chat.completions.create(
                model=MODEL_NAME,
                messages=message,
                temperature=TEMPERATURE,
                top_p=TOP_P,
                max_tokens=MAX_TOKENS,
                stream=True,
            ) as resp:
                async for chunk in resp:
                    try:
                        chunk = chunk.choices[0].delta.content
                        try:
                            if chunk and len(chunk) > 0:
                                message = chunk
                            else:
                                message = ""
                        except Exception as e:
                            logger.info(f"Parsing SLM response chunk '{chunk}' failed. {e}")
                            message = ""

                        if not message:
                            continue

                        full_response += message
                        json_chunk = ChatResponse()
                        json_chunk.Response.Text = message
                        json_chunk.Response.CleanedText = message
                        json_chunk = json.dumps(json_chunk.dict())
                        yield json_chunk
                    except Exception as e:
                        yield f"Internal error in SLM stream: {e}"
                        break

        json_chunk = ChatResponse()
        json_chunk.Response.IsFinal = True
        json_chunk = json.dumps(json_chunk.dict())
        logger.info(f"SLM response for user query {question} : {full_response}")
        yield json_chunk

    return StreamingResponse(generator(), media_type="text/event-stream")


@router.post(
    "/chat",
    status_code=status.HTTP_200_OK,
)
async def chat(
    request: Annotated[
        ChatRequest,
        Body(
            description="Chat Engine Request JSON. All the fields populated as part of this JSON is also available as part of request JSON."
        ),
    ],
    response: Response,
) -> StreamingResponse:
    """
    This endpoint can be used to provide response to query driven user request.
    """
    req = request.dict(exclude_none=True)
    logger.info(f"Received request JSON at /chat_stream endpoint for SLM : {json.dumps(req, indent=4)}")

    try:
        chat_history = []
        if "Metadata" in req:
            chat_history = req["Metadata"].get("ChatHistory", [])
        resp = await stream(question=req["Query"], chat_history=chat_history)
        return resp
    except Exception as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"StatusMessage": str(e)}


@router.post("/event", status_code=status.HTTP_200_OK)
async def event(
    request: Annotated[
        EventRequest,
        Body(
            description="Chat Engine Request JSON. All the fields populated as part of this JSON is also available as part of request JSON."
        ),
    ],
    response: Response,
) -> Union[EventResponse, Dict[str, str]]:
    """
    This endpoint can be used to provide response to an event driven user request.
    """

    req = request.dict(exclude_none=True)
    logger.info(f"Received request JSON at /event endpoint: {json.dumps(req, indent=4)}")

    try:
        resp = EventResponse()
        resp.UserId = req["UserId"]
        resp.Response.IsFinal = True

        if req["EventType"] in EVENTS_NOT_REQUIRING_RESPONSE:
            resp.Response.NeedUserResponse = False

        return resp
    except Exception as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"StatusMessage": str(e)}
