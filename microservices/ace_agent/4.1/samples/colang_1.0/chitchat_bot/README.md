# CHITCHAT BOT USING COLANG
Chitchat bot is a general conversation bot. It supports basic smalltalk queries using colang language.

## Setting up environment
1. Set OpenAI api key
    ```
    export OPENAI_API_KEY=<OPENAI_API_KEY>
    ```

## Deploy the bot
1. Set the BOT_PATH environment variable relative to the current directory.
    ```
    export BOT_PATH=./samples/colang_1.0/chitchat_bot/
    ```
2. Update the PIPELINE in file `deploy/docker/docker_init.sh` to `speech_lite`:
    ```
    export PIPELINE=speech_lite
    ```
3. Set the environment variables required for `docker-compose.yaml` by sourcing `deploy/docker/docker_init.sh`.
    ```
    source deploy/docker/docker_init.sh
    ```
4. Deploy the Speech and NLP models required for the bot which might take 20-40 minutes for the first time. For the chitchat sample bot, Riva ASR (Automatic Speech Recognition) and TTS (Text to Speech) models will be deployed.
    ```
    docker compose -f deploy/docker/docker-compose.yml up model-utils-speech
    ```
5. Deploy the ACE Agent Microservices. The following command deploys the Chat Controller, Chat Engine, Plugin server, and NLP Server Microservices.
    ```
    docker compose -f deploy/docker/docker-compose.yml up speech-bot -d
    ```
6. Wait for a few minutes for all services to be ready. You can check the Docker logs for individual microservices to confirm. You will see log print ``Server listening on 0.0.0.0:50055`` in the Docker logs for the Chat Controller container.
7. You can interact with the bot using the URL ``http://<workstation IP>:7006``.
