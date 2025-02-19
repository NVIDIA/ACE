# SPANISH BOT NMT USING COLANG
Spanish NMT bot provides real-time weather data, provides current date and time information and answers open domain question in spanish.
It internally utilizes Riva NMT to translate a query from Spanish to English and vice-versa for responses.

## Setting up environment
1. Set up virtual environment and Install the nemo-guardrails and aceagent Python packages following Quick Start Guide.
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
2. Set OpenAI api key
    ```
    export OPENAI_API_KEY=<OPENAI_API_KEY>
    ```

## Features
This bot has the following features and functionalities -
1. Weather forecast
2. Temperature
3. Wind Speed
4. Humidity
5. Precipitation
6. Whether the weather condition is Sunny or Cloudy at a given location.
7. Current Date and time.
8. Open domain QnA.


## Deplot the bot

1. Deploy NLP models
    ```
    aceagent models deploy --config bots/spanish_bot_nmt/model_config.yaml
    ```
2. Launch plugin server
    ```
    aceagent plugin-server deploy --config bots/spanish_bot_nmt/plugin_config.yaml
    ```

3. Launch Bot
    ```
    aceagent chat cli --config bots/spanish_bot_nmt
    ```

## Sample Conversation
Once the bot is deployed you can query bot about ACE Agent related question

![Conversation-1](./img/conversation_1.png)
