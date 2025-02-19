# Using RAG in ACE Agent
## Introduction

ACE Agent allows developers to create chatbots which interact with an independently deployed [RAG chain server](https://github.com/NVIDIA/GenerativeAIExamples). If enabled, ACE Agent will redirect all questions to the RAG chain server. This enables RAG use cases with all of the interfaces and integrations available to ACE Agent.

## Usage
- Ensure that there is a RAG server deployed. The default URL expected by ACE Agent is ``http://localhost:8081``. If the server is deployed at a different URL, specify it in the plugin config file, like below:
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

# Deplot the bot
1. Set the BOT_PATH environment variable relative to the current directory.
    ```
    export BOT_PATH=./samples/colang_1.0/rag_bot/
    ```
2. Update the PIPELINE in file `deploy/docker/docker_init.sh` to `speech_lite`:
    ```
    export PIPELINE=speech_lite
    ```
3. Set the environment variables required for `docker-compose.yaml` by sourcing `deploy/docker/docker_init.sh`.
    ```
    source deploy/docker/docker_init.sh
    ```
4. Deploy the Speech and NLP models required for the bot which might take 20-40 minutes for the first time. For the rag sample bot, Riva ASR (Automatic Speech Recognition) and TTS (Text to Speech) models will be deployed.
    ```
    docker compose -f deploy/docker/docker-compose.yml up model-utils-speech
    ```
5. Deploy the ACE Agent Microservices. The following command deploys the Chat Controller, Chat Engine, Plugin server, and NLP Server Microservices.
    ```
    docker compose -f deploy/docker/docker-compose.yml up speech-bot -d
    ```
6. Wait for a few minutes for all services to be ready. You can check the Docker logs for individual microservices to confirm. You will see log print ``Server listening on 0.0.0.0:50055`` in the Docker logs for the Chat Controller container.
7. You can interact with the bot using the URL ``http://<workstation IP>:7006``.
