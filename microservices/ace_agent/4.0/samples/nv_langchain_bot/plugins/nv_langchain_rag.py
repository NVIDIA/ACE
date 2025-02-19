# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from fastapi import APIRouter
from fastapi.responses import StreamingResponse
import logging

logger = logging.getLogger("plugin")
router = APIRouter()

import os

from langchain_community.vectorstores.milvus import Milvus
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.pydantic_v1 import BaseModel
from langchain_core.runnables import (
    RunnableParallel,
    RunnablePassthrough,
)
from langchain_nvidia_ai_endpoints import ChatNVIDIA, NVIDIAEmbeddings

EMBEDDING_MODEL = "nvolveqa_40k"
CHAT_MODEL = "llama2_13b"
HOST = "127.0.0.1"
PORT = "19530"
COLLECTION_NAME = "test"

if os.environ.get("NVIDIA_API_KEY", "").startswith("nvapi-"):
    print("Valid NVIDIA_API_KEY already in environment. Delete to reset")
else:
    raise ValueError("Please export a valid NVIDIA_API_KEY")

# Read from Milvus Vector Store
embeddings = NVIDIAEmbeddings(model=EMBEDDING_MODEL)

# RAG prompt
template = """<s>[INST] <<SYS>>
Use the following context to answer the user's question. If you don't know the answer,
just say that you don't know, don't try to make up an answer.
<</SYS>>
<s>[INST] Context: {context} Question: {question} Only return the helpful
 answer below and nothing else. Helpful answer:[/INST]"
"""
prompt = ChatPromptTemplate.from_template(template)

# RAG
model = ChatNVIDIA(model=CHAT_MODEL)

# Add typing for input
class Question(BaseModel):
    __root__: str


@router.post("/generate")
async def generate(question: str) -> StreamingResponse:
    """Call the streaming method of the chain"""

    vectorstore = Milvus(
        connection_args={"host": HOST, "port": PORT},
        collection_name=COLLECTION_NAME,
        embedding_function=embeddings,
    )
    retriever = vectorstore.as_retriever()

    chain = (
        RunnableParallel({"context": retriever, "question": RunnablePassthrough()})
        | prompt
        | model
        | StrOutputParser()
    )
    chain = chain.with_types(input_type=Question)

    async def generator():
        async for chunk in chain.astream(question):
            yield chunk

    return StreamingResponse(generator(), media_type="text/event-stream")
