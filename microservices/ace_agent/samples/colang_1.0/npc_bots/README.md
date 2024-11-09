# BOTS FOR GAMING USECASES
This directory contains sample bots showcasing how developers can build:
1. LLM driven Natural Language Understanding and Natural Language Generation capabilities for Non-Playable Characters in a game
2. Provide game-stage specific context to Chat Engine at runtime and utlize the same to change the behaviour of NPC's.

## Setting up environment
1. The bots uses nemollm models. Export your NGC CLI key which has access to nemo llm service.
    ```
    export NGC_CLI_API_KEY=<>
    ```
2. Set NVIDIA API Key
    ```
    export NVIDIA_API_KEY=<NVIDIA_API_KEY>

## Deploy all the bots
1. Set the BOT_PATH environment variable relative to the current directory.
    ```
    export BOT_PATH=./samples/colang_1.0/npc_bots/<character_name>
    ```
2. Update the PIPELINE in file `deploy/docker/docker_init.sh` to `speech_lite`:
    ```
    export PIPELINE=speech_lite
    ```
3. Set the environment variables required for `docker-compose.yaml` by sourcing `deploy/docker/docker_init.sh`.
    ```
    source deploy/docker/docker_init.sh
    ```
4. Deploy the Speech and NLP models required for the bot which might take 20-40 minutes for the first time. For the npc sample bots, Riva ASR (Automatic Speech Recognition) and TTS (Text to Speech) models will be deployed.
    ```
    docker compose -f deploy/docker/docker-compose.yml up model-utils-speech
    ```
5. Deploy the ACE Agent Microservices. The following command deploys the Chat Controller, Chat Engine, Plugin server, and NLP Server Microservices.
    ```
    docker compose -f deploy/docker/docker-compose.yml up speech-bot -d
    ```
6. Wait for a few minutes for all services to be ready. You can check the Docker logs for individual microservices to confirm. You will see log print ``Server listening on 0.0.0.0:50055`` in the Docker logs for the Chat Controller container.
7. You can interact with the bot using the URL ``http://<workstation IP>:7006``.
