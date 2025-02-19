# STOCK FAQ BOT USING COLANG
Stock FAQ bot is able to answer queries related to stocks and stock market.

## Setting up environment
1. Set NVIDIA API Key
    ```
    export NVIDIA_API_KEY=<NVIDIA_API_KEY>
    ```

## Features
This bot has the following features and functionalities -
1. Get stock price of a particular organization
2. Answer queries related to stock market and related concepts

## Deplot the bot
1. Set the BOT_PATH environment variable relative to the current directory.
    ```
    export BOT_PATH=./samples/colang_1.0/stock_bot/
    ```
2. Update the PIPELINE in file `deploy/docker/docker_init.sh` to `speech_lite`:
    ```
    export PIPELINE=speech_lite
    ```
3. Set the environment variables required for `docker-compose.yaml` by sourcing `deploy/docker/docker_init.sh`.
    ```
    source deploy/docker/docker_init.sh
    ```
4. Deploy the Speech and NLP models required for the bot which might take 20-40 minutes for the first time. For the stock sample bot, Riva ASR (Automatic Speech Recognition) and TTS (Text to Speech) models will be deployed.
    ```
    docker compose -f deploy/docker/docker-compose.yml up model-utils-speech
    ```
5. Deploy the ACE Agent Microservices. The following command deploys the Chat Controller, Chat Engine, Plugin server, and NLP Server Microservices.
    ```
    docker compose -f deploy/docker/docker-compose.yml up speech-bot -d
    ```
6. Wait for a few minutes for all services to be ready. You can check the Docker logs for individual microservices to confirm. You will see log print ``Server listening on 0.0.0.0:50055`` in the Docker logs for the Chat Controller container.
7. You can interact with the bot using the URL ``http://<workstation IP>:7006``.
