# FOOD ORDERING BOT USING COLANG
Food ordering bot is a virtual assistant bot which can help you with placing your food order. It can list items from menu,
add, remove and replace items in your cart and help you place the order.

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
1. Listing menu items
2. Managing order cart
3. Listing bill amount
4. Showcasing use of entry/exit events.


## Deploy the bot

1. Deploy NLP models
    ```
    aceagent models deploy --config bots/food_ordering_bot/model_config.yaml
    ```
2. Launch Bot
    ```
    aceagent chat cli --config bots/food_ordering_bot
    ```
    ```

## Sample Conversation
Once the bot is deployed you can query bot about ACE Agent related question

![Conversation-1](../img/food_ordering_conversation.png)
