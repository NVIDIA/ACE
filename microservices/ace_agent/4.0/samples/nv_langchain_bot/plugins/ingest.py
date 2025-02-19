# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

import os

from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import CharacterTextSplitter
from langchain.vectorstores.milvus import Milvus
from langchain_nvidia_ai_endpoints import NVIDIAEmbeddings

if os.environ.get("NVIDIA_API_KEY", "").startswith("nvapi-"):
    print("Valid NVIDIA_API_KEY already in environment. Delete to reset")
else:
    raise ValueError(f"NVIDIA_API_KEY is not found. Please export it as an environment variable.")

EMBEDDING_MODEL = "nvolveqa_40k"
HOST = "127.0.0.1"
PORT = "19530"
COLLECTION_NAME = "test"

embeddings = NVIDIAEmbeddings(model=EMBEDDING_MODEL)

if __name__ == "__main__":
    # Load docs
    loader = PyPDFLoader("https://www.ssa.gov/news/press/factsheets/basicfact-alt.pdf")
    data = loader.load()

    # Split docs
    text_splitter = CharacterTextSplitter(chunk_size=300, chunk_overlap=100)
    docs = text_splitter.split_documents(data)

    # Insert the documents in Milvus Vector Store
    vector_db = Milvus.from_documents(
        docs,
        embeddings,
        collection_name=COLLECTION_NAME,
        connection_args={"host": HOST, "port": PORT},
    )
