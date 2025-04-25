# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

"""
Tokkio LLM services with filler phrase support for handling response delays.

These services extend the base LLM services to provide a more natural conversational
experience by speaking filler phrases during response delays. This is particularly useful when 
using a RAG service that is slow to respond.

To implement this, we extend the base LLM / RAG services and override the _process_context method.

In order to use this functionality, you will need to update config.yaml to use the TokkioLLMService
which will updated the bot pipeline in the bot.py file to use the TokkioLLMService
instead of the base NvidiaLLMService. 

You may configure the filler phrases in the config.yaml file as well. 

Below is an example of how to update the config.yaml file to specify the filler phrases:

Example usage:
    filler_phrases = [
        "Let me think about that...",
        "One moment please...",
        "Hmm, good question...",
        "Let me process that..."
    ]
"""

import asyncio
import time
from loguru import logger
import random

from pipecat.frames.frames import TextFrame, TTSSpeakFrame
from pipecat.processors.aggregators.openai_llm_context import OpenAILLMContext
from nvidia_pipecat.services.nvidia_llm import NvidiaLLMService
from pipecat.services.openai import OpenAILLMService


class TokkioLLMServiceMixin:

    async def _process_context_common(self, context: OpenAILLMContext, stream_chat_completions):
        """Common implementation for processing LLM context with filler phrase support.
        
        Args:
            context: The OpenAI LLM context to process
            stream_chat_completions: Async function that returns a chunk stream
        """
        await self.start_ttfb_metrics()
        
        first_chunk_received = False
        filler_said = False
        start_time = time.time()

        # Create a task to monitor the request time and trigger filler phrase if needed
        async def monitor_request_time():
            nonlocal filler_said
            await asyncio.sleep(self.time_delay)
            if not first_chunk_received and not filler_said:
                filler_said = True
                random_filler = random.choice(self.filler)
                await self.push_frame(TTSSpeakFrame(random_filler))
        
        # Start the monitoring task
        monitor_task = asyncio.create_task(monitor_request_time())

        try:
            chunk_stream = await stream_chat_completions(context)
            async for chunk in chunk_stream:
                if not first_chunk_received:
                    elapsed_time = time.time() - start_time
                    logger.debug(f"Elapsed time: {elapsed_time}")
                    logger.debug(f"Time delay: {self.time_delay}")
                    first_chunk_received = True
                    
                    # Cancel the monitoring task since we've received a response
                    if not monitor_task.done():
                        monitor_task.cancel()
                        try:
                            await monitor_task
                        except asyncio.CancelledError:
                            pass

                # Handle OpenAI chunk format
                if hasattr(chunk, 'choices') and chunk.choices and chunk.choices[0].delta:
                    if chunk.choices[0].delta.content:
                        await self.stop_ttfb_metrics()
                        await self.push_frame(TextFrame(chunk.choices[0].delta.content))
                # Handle Nvidia chunk format
                elif hasattr(chunk, 'content') and chunk.content:
                    await self.stop_ttfb_metrics()
                    await self.push_frame(TextFrame(chunk.content))
                # Warn if chunk format is unexpected
                else:
                    logger.warning(f"Received chunk in unexpected format: {type(chunk).__name__}. Content: {chunk}")
        except Exception as e:
            logger.error(f"An error occurred in http request to LLM endpoint, Error: {e}")
            await self.push_frame(TTSSpeakFrame("Cannot connect to the LLM endpoint"))

        finally:
            # Ensure the monitor task is cancelled if it's still running
            if not monitor_task.done():
                monitor_task.cancel()
                try:
                    await monitor_task
                except asyncio.CancelledError:
                    pass


class TokkioNvidiaLLMService(NvidiaLLMService, TokkioLLMServiceMixin):
    def __init__(self, filler: list[str], time_delay: float = 1.0, **kwargs):
        """Initialize TokkioLLMService, ensuring NvidiaLLMService is properly initialized."""
        self.filler = filler
        self.time_delay = time_delay
        super().__init__(**kwargs)

    async def _process_context(self, context: OpenAILLMContext):
        """Process an LLM context and stream back partial completions,
        injecting a filler message after the specified time delay if streaming has not begun."""
        await self._process_context_common(context, self._stream_chat_completions)


class TokkioOpenAILLMService(OpenAILLMService, TokkioLLMServiceMixin):
    def __init__(self, filler: list[str], time_delay: float = 1.0, **kwargs):
        """Initialize TokkioOpenAILLMService, ensuring OpenAILLMService is properly initialized."""
        self.filler = filler
        self.time_delay = time_delay
        super().__init__(**kwargs)

    async def _process_context(self, context: OpenAILLMContext):
        """Process an LLM context and stream back partial completions,
        injecting a filler message after the specified time delay if streaming has not begun."""
        await self._process_context_common(context, self._stream_chat_completions)