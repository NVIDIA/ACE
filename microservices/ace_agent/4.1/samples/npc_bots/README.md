# BOTS FOR GAMING USECASES
This directory contains sample bots showcasing how developers can build:
1. LLM driven Natural Language Understanding and Natural Language Generation capabilities for Non-Playable Characters in a game
2. Provide game-stage specific context to Chat Engine at runtime and utlize the same to change the behaviour of NPC's.

## Architecture diagram of the NPC bot
![Diagram](../img/npc_bot_arch_diagram.jpg)

## Setting up environment
1. Set up virtual environment and Install the nemo-guardrails and aceagent Python packages following Quick Start Guide.
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
2. The bots uses nemollm models. Export your NGC CLI key which has access to nemo llm service.
    ```
    export NGC_CLI_API_KEY=<>
    ```

## Deploy all the bots
1. Launch plugin server for the bots. The fulfillment module is responsible to generate [a custom instruction which gets injected as part of the prompts for generating the response](./jin/bot_config.yaml#L53). The logic to generate this custom instruction is coded [in this file](./plugins/prompt_former.py). Developers are free to change or fine tune the logic to generate custom instructions for the prompt here.
    ```
    aceagent plugin-server deploy --config bots/npc_bots/plugin_config.yaml &
    ```

2. Launch all the Bots by passing the bot directory path. chat engine automatically discovers all the available bots in this directory and hosts them.
   The LLM configurations and backstory of the characters is exposed for fine-tuning in every bot specific config files. The config files are named as `bot_config.yaml` and every bot directory has its own seperate version of it.
    ```
    aceagent chat web --config bots/npc_bots
    ```

## Sample Conversation
Once the bot is deployed you can interact with any bot at `http://<workstation_ip>:9001/bot/` by choosing the bot name and version from the dropdown list.

![Conversation-1](../img/npc_bot_conversation.png)


## Providing game stage specific context
Any custom parameters can be provided for an user at runtime. These parameters can be utilized to update the bot behaviour whose example is shown here. This can be done using the `/updateUserContext` API of Chat Engine at runtime, without restarting the pipeline. In a gaming scenario, this can be useful to pass game specific user context to control bot behaviour.
1. Once the bot is deployed, goto the Chat Engine server swagger URL `http://<workstation_ip>:9000/docs`
2. Try out the `/updateUserContext` API by providing the following request body. Change the values of parameters as needed.
   The key-value pairs provided as part of the payload to this API, will be visible to [the custom fulfillment as well.](./plugins/prompt_former.py)
   Currently, fulfillment module utlizes these parameters at runtime to formulate the custom instuctions which gets injected as part of the prompt sent to LLM.
   Default values for these parameters are available in [`plugin_config.yaml` file](./plugin_config.yaml).

   Provide the following payload for `/updateUserContext` API. Note the `UserId` for the queries you tried out using `http://<workstation_ip>:9001/bot/` from the terminal in logs and provide the same below to update user context for the existing user which was auto created when you launched the web console.
   ```
   {
   "quality": 9, "toxicity":8, "humor": 2, "creativity":7, "violence":6, "helpfulness": 2, "not_appropriate": 0
   }
   ```
3. Retry some queries with the bot at `http://<workstation_ip>:9001/bot/`, the bot behaviour should reflect the runtime changes in user parameters.


## Deleting game stage specific context
User context can be deleted at runtime using `/deleteUserContext` API of Chat Engine. This API can be used to clear the conversation history. In a gaming scenario, this can be useful to reset the game state, when a game restarts for example.
1. Once the bot is deployed, goto the Chat Engine server swagger URL `http://<workstation_ip>:9000/docs`
2. Try out the `/deleteUserContext` API by providing the following request body.
   Provide the following payload for `/updateUserContext` API. Note the `UserId` for the queries you tried out using `http://<workstation_ip>:9001/bot/` from the terminal in logs and provide the same below to update user context for the existing user which was auto created when you launched the web console.
   ```
   {
   "UserId": "<Check the userid from the dm logs>",
   }
   ```
3. Retry some queries with the bot at `http://<workstation_ip>:9001/bot/`, the bot behaviour should reflect the fact that previous conversation history is no longer available.


## Handling game load and save scenarios

### Game load scenario
During a game load scenario, to set a custom conversation history and context for a specific user can be done using `/setUserContext` API of Chat Engine. This is useful when you want to load a saved game context for a specific user.
1. Once the bot is deployed, goto the Chat Engine server swagger URL `http://<workstation_ip>:9000/docs`
2. Try out the `/setUserContext` API by providing the following request body. This will overwrite any existing conversation history and user context.
 Note the `UserId` for the queries you tried out using `http://<workstation_ip>:9001/bot/` from the terminal in logs and provide the same below to update user context which was auto created when you launched the web console.
```
{
  "UserId": "<Check the userid from the dm logs>",
  "Context": {
    "quality": 9,
    "toxicity": 8,
    "humor": 2,
    "creativity": 7,
    "violence": 6,
    "helpfulness": 2,
    "not_appropriate": 0
  },
  "ChatHistory": {
    "jin": [
      {
        "role": "user",
        "content": "hello"
      },
      {
        "role": "assistant",
        "content": "Hello, Kai. I hope you are doing well. If you ask any other question I will be angry."
      }
    ],
    "elara": [
      {
        "role": "user",
        "content": "hello"
      },
      {
        "role": "assistant",
        "content": "Kai, are you feeling alright? You are not making a lot of sense right now. And you are not answering my question."
      }
    ]
  }
}
```
3. Retry some queries with the bot at `http://<workstation_ip>:9001/bot/`, the bot behaviour should reflect the fact that a custom conversation history is being loaded.


### Game save scenario
Developers can extract the conversation history and user context from chat engine for a specific user and choose to save it on the application side. This can be done using `/getUserContext` API. To extract the user context for specific user id provide the following payload:
```
   {
   "UserId": "<Check the userid from the dm logs>"
   }
```