# Using RAG in ACE Agent
## Introduction

ACE Agent allows developers to create chatbots which interact with an independently deployed [RAG chain server](https://github.com/NVIDIA/GenerativeAIExamples). If enabled, ACE Agent will redirect all questions to the RAG chain server. This enables RAG use cases with all of the interfaces and integrations available to ACE Agent.

## Usage

- Ensure that there is a RAG server deployed. The default URL expected by ACE Agent is ``http://localhost:8081``. If the server is deployed at a different URL, specify it in the fulfillment config file, like below:
    ```shell
    plugins:
      - name: rag
        parameters:
          RAG_SERVER_URL: "http://<your-ip>"
    ```
    Also, ensure that the required documents are ingested into the RAG server. ACE Agent is not responsible for document ingestion.

- In the bot config file, ensure that the bot name begins with the prefix ``rag``. This enables the RAG policy which redirects queries to the ``/generate`` endpoint of the RAG server.
- Start and interact with the bot similar to other ACE Agent bots.
- In server mode of ACE Agent, both streaming and non-streaming endpoints are compatible with RAG policy.