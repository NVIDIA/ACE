# CHITCHAT BOT USING COLANG
Chitchat bot is a general conversation bot. It supports basic smalltalk queries using colang language.

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

## Deploy the bot
1. Launch Bot
    ```
    aceagent chat cli --config bots/chitchat_bot
    ```

## Sample Conversation
Once the bot is deployed you can query bot about ACE Agent related question

![Conversation-1](./img/conversation_1.png)
