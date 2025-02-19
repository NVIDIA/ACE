# STOCK FAQ BOT USING COLANG
Stock FAQ bot is able to answer queries related to stocks and stock market.

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
1. Get stock price of a particular organization
2. Answer queries related to stock market and related concepts

## Deplot the bot
1. Launch plugin server
    ```
    aceagent plugin-server deploy --config bots/stock_bot/plugin_config.yaml
    ```

2. Launch Bot
    ```
    aceagent chat cli --config bots/stock_bot
    ```

## Sample Conversation
Once the bot is deployed you can query bot about ACE Agent related question

![Conversation-1](../img/stock_bot_conversation.png)
