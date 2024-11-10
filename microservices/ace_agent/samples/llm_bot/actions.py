"""
 copyright(c) 2024 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""

import os
import time
import asyncio
import logging

from typing import List
from datetime import datetime
from openai import AsyncOpenAI
from nemoguardrails.actions.actions import action
from chat_engine.policies.actions.colang2_actions import create_chat_history


logger = logging.getLogger("nemoguardrails")


def log(what: str):
    """Log compatible with the nemoguardrails log output to show output as part of logging output"""
    logger.info(f"A Colang debug info: {what}")


## LLM Configs
BASE_URL = "http://0.0.0.0:8010/v1"  # Set to "https://integrate.api.nvidia.com/v1" for using hosted NIM models and provide API key using NVIDIA_API_KEY env variable
MODEL = "meta/llama3-8b-instruct"
TEMPERATURE = 0.5
TOP_P = 1
MAX_TOKENS = 100
SYSTEM_PROMPT = "You are a helpful, respectful and honest assistant. Always answer as helpful friendly and polite. Respond with one sentence or less than 75 characters. Do not respond with bulleted or numbered list. Your output will be converted to audio so don't include special characters in your answers."

client = AsyncOpenAI(
    base_url=BASE_URL, api_key=os.getenv("NVIDIA_API_KEY") or "$API_KEY_REQUIRED_IF_NOT_USING_LOCAL_MODEL"
)

# Transcript filtering for spurious transcript and filler words. Along with this any transcript less than 3 chars is removed
FILTER_WORDS = [
    "yeah",
    "okay",
    "right",
    "yes",
    "yum",
    "and",
    "one",
    "all",
    "when",
    "thank",
    "but",
    "next",
    "what",
    "i see",
    "the",
    "hmm",
    "mmm",
    "so that",
    "why",
    "that",
    "well",
]

INCLUDE_WORDS = ["hi"]


@action(name="ExternalLLMAction", execute_async=True)
async def call_nim_local_llm(events: List, query: str, min_wait_time: float = 0.2) -> str:
    """
    Call LLM for given query with chat history
    """

    log(f"{datetime.now()} Started LLM call, {time.time()} for query `{query}`")
    chat_history = create_chat_history(events)
    print(f"chat_history for {query}", chat_history)
    messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT,
        }
    ]
    messages.extend(chat_history)
    messages.append({"role": "user", "content": query})
    start = time.time()
    completion = await client.chat.completions.create(
        model=MODEL,
        messages=messages,
        temperature=TEMPERATURE,
        top_p=TOP_P,
        max_tokens=MAX_TOKENS,
        stream=True,
    )

    response = ""
    async for chunk in completion:
        if chunk.choices[0].delta.content is not None:
            response += chunk.choices[0].delta.content
    llm_latency = time.time() - start
    log(f"{datetime.now()}, LLM call latency {time.time()-start}, response: {response}")
    if llm_latency < min_wait_time:
        log(f"LLM call finished before minimum wait time {min_wait_time}, waiting for {min_wait_time-llm_latency}")
        await asyncio.sleep(min_wait_time - llm_latency)
    return response


@action(name="IsSpuriousAction")
async def is_spurious(query):
    """
    Filter transcript less than 3 chars or in FILTER_WORDS list to avoid spurious transcript and filler words.
    """
    if query.strip().lower() in FILTER_WORDS or (len(query) < 3 and query.strip().lower() not in INCLUDE_WORDS):
        return True
    else:
        return False
