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

from typing import Dict, Optional, Union, List

import aiohttp
from fastapi import APIRouter, Body, Response, status
from fastapi.responses import StreamingResponse
from parameters import param
from typing_extensions import Annotated
from utils import validate_url

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


@router.get("/rag_endpoint_url")
def get_rag_endpoint() -> str:
    """
    This function returns the currently configured rag server endpoint.
    """
    global RAG_SERVER_URL
    return RAG_SERVER_URL


@router.post("/rag_endpoint_url")
def set_rag_endpoint(rag_endpoint_url: str) -> bool:
    """
    This function allows updating the rag server endpoint dynamically.

    Args:
        rag_endpoint_url.
        Example: http://10.222.22.23:8081

    Returns:
        True if the update is successful, False otherwise.
    """
    if validate_url(rag_endpoint_url):
        logger.info("Updating the RAG server endpoint to: {}".format(rag_endpoint_url))
        global GENERATION_URL
        global RAG_SERVER_URL

        RAG_SERVER_URL = rag_endpoint_url
        GENERATION_URL = f"{RAG_SERVER_URL}/generate"
        return True
    else:
        logger.error(
            "Error updating the RAG server endpoint to {}. Please check the validity of the input.".format(
                rag_endpoint_url
            )
        )

    return False


async def stream(
    question: Optional[str] = "",
    chat_history: Optional[List] = [],
    num_tokens: Optional[int] = MAX_TOKENS,
) -> int:
    """
    Call the RAG chain server and return the streaming response.
    """
    question = (
        question + "\n Respond with one sentence or less than 75 characters until user tells to give longer answers."
    )

    request_json = {
        "messages": chat_history + [{"role": "user", "content": question}],
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
                                    logger.debug(f"Received empty RAG response chunk '{chunk}'.")
                                    message = ""
                            except Exception as e:
                                logger.warning(f"Parsing RAG response chunk '{chunk}' failed. {e}")
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

        logger.info(f"Full RAG response for query `{question}` : {full_response}")
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
    logger.info(f"Received request JSON at /chat_stream endpoint for RAG : {json.dumps(req, indent=4)}")

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
