# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

import json
import logging
import os
import sys
from typing import Dict, Optional, Union

import aiohttp
from fastapi import APIRouter, Body, Response, status
from fastapi.responses import StreamingResponse
from parameters import param
from typing_extensions import Annotated

sys.path.append(os.path.dirname(__file__))

from schemas import ChatRequest, EventRequest, EventResponse, ChatResponse

logger = logging.getLogger("plugin")
router = APIRouter()

# RAG related parameters
RAG_SERVER_URL = os.getenv("RAG_SERVER_URL", None) or param.get("rag").get("RAG_SERVER_URL", "http://localhost:8081")
STOP_WORDS = os.getenv("STOP_WORDS", None) or param.get("rag").get("STOP_WORDS", [])
TEMPERATURE = os.getenv("TEMPERATURE", None) or param.get("rag").get("TEMPERATURE", 0.2)
TOP_P = os.getenv("TOP_P", None) or param.get("rag").get("TOP_P", 0.7)
MAX_TOKENS = os.getenv("MAX_TOKENS", None) or param.get("rag").get("MAX_TOKENS", 200)

GENERATION_URL = f"{RAG_SERVER_URL}/generate"

EVENTS_NOT_REQUIRING_RESPONSE = [
    "system.event_pipeline_acquired",
    "system.event_pipeline_released",
    "system.event_exit",
]


async def stream(
    question: Optional[str] = "",
    retrieval_context: Optional[str] = "",
    num_tokens: Optional[int] = MAX_TOKENS,
) -> int:
    """
    Call the RAG chain server and return the streaming response.
    """
    request_json = {
        "messages": [{"role": "user", "content": question}],
        "use_knowledge_base": True,
        "temperature": TEMPERATURE,
        "top_p": TOP_P,
        "max_tokens": num_tokens,
        "seed": 42,
        "bad": [],
        "stop": STOP_WORDS,
        "stream": True,
    }

    # Method that forwards the stream to the Chat controller
    async def generator():

        full_response = ""
        if question:
            async with aiohttp.ClientSession() as session:
                async with session.post(GENERATION_URL, json=request_json) as resp:
                    async for chunk, _ in resp.content.iter_chunks():
                        try:
                            chunk = chunk.decode("utf-8")
                            chunk = chunk.strip("\n")

                            try:
                                if len(chunk) > 6:
                                    parsed = json.loads(chunk[6:])
                                    message = parsed["choices"][0]["message"]["content"]
                                else:
                                    logger.info(f"Received empty RAG response chunk '{chunk}'.")
                                    message = ""
                            except Exception as e:
                                logger.info(f"Parsing RAG response chunk '{chunk}' failed. {e}")
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
                            yield f"Internal error in RAG stream: {e}"
                            break

        json_chunk = ChatResponse()
        json_chunk.Response.IsFinal = True
        json_chunk = json.dumps(json_chunk.dict())
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
    logger.info(f"Received request JSON at /chat_stream endpoint: {json.dumps(req, indent=4)}")

    try:
        resp = await stream(question=req["Query"])
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
