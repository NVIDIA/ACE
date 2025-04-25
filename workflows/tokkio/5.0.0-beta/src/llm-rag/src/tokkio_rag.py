# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

"""
Tokkio RAG (Retrieval-Augmented Generation) service with filler phrase support.

This service extends the base NvidiaRAGService to provide a more natural conversational
experience by speaking filler phrases during response delays. This is particularly useful
since RAG operations often involve document retrieval and processing that can take time.

The service adds the following enhancements:
- Filler phrases during response delays
- Configurable time delay threshold before speaking fillers
- Maintains all core RAG functionality from NvidiaRAGService

To use this functionality, update your config.yaml to use TokkioNvidiaRAGService
and specify your desired filler phrases.

Example config.yaml:
    rag_service:
        type: "TokkioNvidiaRAGService"
        filler_phrases:
            - "Let me search through my knowledge base..."
            - "I'm retrieving relevant information..."
            - "Looking through the documents..."
            - "Analyzing the relevant content..."
        time_delay: 1.0  # Seconds to wait before using filler phrase
"""

import asyncio
import time
from loguru import logger
import random
import json

from pipecat.frames.frames import TextFrame, TTSSpeakFrame, ErrorFrame
from pipecat.processors.aggregators.openai_llm_context import OpenAILLMContext
from nvidia_pipecat.services.nvidia_rag import NvidiaRAGService
from openai.types.chat import ChatCompletionMessageParam
from nvidia_pipecat.frames.nvidia_rag import NvidiaRAGCitation, NvidiaRAGCitationsFrame
from nvidia_pipecat.utils.tracing import traceable, AttachmentStrategy, traced

@traceable
class TokkioNvidiaRAGService(NvidiaRAGService):
    def __init__(
        self,
        collection_name: str,
        filler: list[str],
        time_delay: float = 1.0,
        rag_server_url: str = "http://localhost:8081",
        stop_words: list | None = None,
        temperature: float = 0.2,
        top_p: float = 0.7,
        max_tokens: int = 200,
        use_knowledge_base: bool = True,
        vdb_top_k: int = 20,
        reranker_top_k: int = 4,
        enable_citations: bool = True,
        suffix_prompt: str | None = None,
        **kwargs
    ):
        """Initialize TokkioRAGService, ensuring NvidiaRAGService is properly initialized."""
        self.filler = filler
        self.time_delay = time_delay
        self.timeout = 120 # Request timeout value. If no chunks are received within this time duration, the endpoint is considered to be unreachable.
        
        # Pass all RAG-specific parameters to parent
        super().__init__(
            collection_name=collection_name,
            rag_server_url=rag_server_url,
            stop_words=stop_words,
            temperature=temperature,
            top_p=top_p,
            max_tokens=max_tokens,
            use_knowledge_base=use_knowledge_base,
            vdb_top_k=vdb_top_k,
            reranker_top_k=reranker_top_k,
            enable_citations=enable_citations,
            suffix_prompt=suffix_prompt,
            **kwargs
        )

    @traced(attachment_strategy=AttachmentStrategy.NONE, name="rag")
    async def _get_rag_response(self, request_json: dict):
        resp = await self.shared_session.post(f"{self.rag_server_url}/generate", json=request_json)
        return resp
    
    async def _process_context(self, context: OpenAILLMContext):
        try:
            messages: list[ChatCompletionMessageParam] = context.get_messages()
            chat_details = []

            for msg in messages:
                if msg["role"] != "system" and msg["role"] != "user" and msg["role"] != "assistant":
                    raise Exception(f"Unexpected role {msg['role']} found!")
                chat_details.append({"role": msg["role"], "content": msg["content"]})

            if self.suffix_prompt:
                for i in range(len(chat_details) - 1, -1, -1):
                    if chat_details[i]["role"] == "user":
                        chat_details[i]["content"] += f" {self.suffix_prompt}"
                        break

            logger.debug(f"Chat details: {chat_details}")

            if len(chat_details) == 0 or all(msg["content"] == "" for msg in chat_details) or not self.collection_name:
                raise Exception("No query or collection name is provided..")

            """
            Call the RAG chain server and return the streaming response.
            """
            request_json = {
                "messages": chat_details,
                "use_knowledge_base": self.use_knowledge_base,
                "temperature": self.temperature,
                "top_p": self.top_p,
                "max_tokens": self.max_tokens,
                # "vdb_top_k": self.vdb_top_k,
                # "reranker_top_k": self.reranker_top_k,
                "collection_name": self.collection_name,
                "stop": self.stop_words,
                "enable_citations": self.enable_citations,
            }

            await self.start_ttfb_metrics()
            
            start_time = time.time()
            first_chunk_received = False
            full_response = ""
            
            # Create a flag to track if we've already said a filler phrase
            filler_said = False
            
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
            resp = await self._get_rag_response(request_json)
            try:
                chunk = ""
                async for current_chunk, _ in resp.content.iter_chunks():
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

                    if not current_chunk:
                        continue

                    await self.stop_ttfb_metrics()

                    citations = []
                    try:
                        current_chunk = current_chunk.decode("utf-8")
                        current_chunk = current_chunk.strip("\n")

                        # When citations are returned in the response, the chunks are getting truncated.
                        # Hence, aggregating them below.
                        if current_chunk.startswith("data: "):
                            chunk = current_chunk
                        else:
                            chunk += current_chunk

                        try:
                            if len(chunk) > 6:
                                parsed = json.loads(chunk[6:])
                                message = parsed["choices"][0]["message"]["content"]
                                if "citations" in parsed:
                                    for citation in parsed["citations"]["results"]:
                                        citations.append(
                                            NvidiaRAGCitation(
                                                document_type=str(citation["document_type"]),
                                                document_id=str(citation["document_id"]),
                                                document_name=str(citation["document_name"]),
                                                content=str(citation["content"]).encode(),
                                                metadata=str(citation["metadata"]),
                                                score=float(citation["score"]),
                                            )
                                        )
                            else:
                                logger.warning(f"Received empty RAG response chunk '{chunk}'.")
                                message = ""

                        except Exception as e:
                            # If json parsing of chunk is getting failed, it means we still don't have the final
                            # aggregated version of the chunk from RAG or erroneous chunk is received from RAG
                            logger.debug(f"Parsing RAG response chunk failed. Error: {e}")
                            message = ""
                        if not message and not citations:
                            continue
                        full_response += message
                        if citations:
                            logger.debug(f"Received RAG citations {citations}")
                            await self.push_frame(NvidiaRAGCitationsFrame(citations=citations))
                        if message:
                            await self.push_frame(TextFrame(message))
                    except Exception as e:
                        await self.push_error(ErrorFrame("Internal error in RAG stream: " + str(e)))
            finally:
                resp.close()
            logger.debug(f"Full RAG response: {full_response}")

        except Exception as e:
            logger.error(f"An error occurred in http request to RAG endpoint, Error:  {e}")
            await self.push_frame(TTSSpeakFrame("Cannot connect to the RAG endpoint"))
            return

