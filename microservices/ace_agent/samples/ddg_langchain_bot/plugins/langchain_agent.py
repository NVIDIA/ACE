# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from fastapi import APIRouter, status, Body, Response
from fastapi.responses import StreamingResponse
import logging
import os
import sys
from typing_extensions import Annotated
from typing import Union, Dict
import json

from langchain_community.chat_models import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain.memory import ChatMessageHistory
from langchain.tools.ddg_search import DuckDuckGoSearchRun
from langchain_core.runnables import (
    RunnableParallel,
    RunnablePassthrough,
)
from langchain.tools import tool

logger = logging.getLogger("plugin")
router = APIRouter()

sys.path.append(os.path.dirname(__file__))

from schemas import ChatRequest, EventRequest, EventResponse, ChatResponse

EVENTS_NOT_REQUIRING_RESPONSE = [
    "system.event_pipeline_acquired",
    "system.event_pipeline_released",
    "system.event_exit",
]

duckduckgo = DuckDuckGoSearchRun()


@tool
def ddg_search(query: str):
    """Performs a duckduck go search"""

    logger.info(f"Input to DDG: {query}")
    answer = duckduckgo.run(query)
    logger.info(f"Answer from DDG: {answer}")
    return answer


rephraser_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            f"You are an assistant whose job is to rephrase the question into a standalone question, based on the conversation history."
            f"The rephrased question should be as short and simple as possible. Do not attempt to provide an answer of your own!",
        ),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{query}"),
    ]
)

wiki_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "Answer the given question from the provided context. Only use the context to form an answer.\nContext: {context}",
        ),
        ("user", "{query}"),
    ]
)

chat_history_map = {}
llm = ChatOpenAI(model="gpt-4-turbo")
output_parser = StrOutputParser()

chain = (
    rephraser_prompt
    | llm
    | output_parser
    | RunnableParallel({"context": ddg_search, "query": RunnablePassthrough()})
    | wiki_prompt
    | llm
    | output_parser
)

chain_with_history = RunnableWithMessageHistory(
    chain,
    lambda session_id: chat_history_map.get(session_id),
    input_messages_key="query",
    history_messages_key="history",
)


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
    logger.info(f"Received request JSON at /chat endpoint: {json.dumps(req, indent=4)}")

    try:

        session_id = req["UserId"]
        question = req["Query"]

        if session_id not in chat_history_map:
            chat_history_map[session_id] = ChatMessageHistory(messages=[])

        def generator(question: str, session_id: str):

            full_response = ""
            if question:
                for chunk in chain_with_history.stream(
                    {"query": question}, config={"configurable": {"session_id": session_id}}
                ):
                    if not chunk:
                        continue
                    full_response += chunk

                    json_chunk = ChatResponse()
                    json_chunk.Response.Text = chunk
                    json_chunk.Response.CleanedText = chunk
                    json_chunk = json.dumps(json_chunk.dict())
                    yield json_chunk

            json_chunk = ChatResponse()
            json_chunk.Response.IsFinal = True
            json_chunk = json.dumps(json_chunk.dict())
            yield json_chunk

        return StreamingResponse(generator(question, session_id), media_type="text/event-stream")

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
