# Event Interface Tutorial Bot

This is the template for event interface tutorial. You need it if you follow the tutorial on how to build a bot using
Colang 2.0 and the event interface
(Section `Building a Bot using Colang 2.0 and Event Interface` of the ACE Agent Documentation)

In this tutorial you will learn how to work with the ACE Agent event interface and how to create a simple bot
that makes use of Colang 2.0 and asynchronous event processing. The bot will feature:

- Multimodality. The bot will make use of gestures, utterances and showing information on a UI.
- LLM integration. The bot will make different use of LLMs to provide contextual answers and to simplify user input handling.
- Proactivity. The bot will be proactive and will try to engage the user if no reply is given.
- Interruptibility. The user can interrupt the bot at any time.
- Back-channeling. The bot can react in real time based on ongoing user input to make your interactions interesting.

## This template

The template provided serves as a minimal setup for the bot tutorial. The Colang script in the template is only
producing a hello world message and will not react to any user input. Instead this is meant as the starting point that
you will expand by following the steps described in the tutorial `Building a Bot using Colang 2.0 and Event Interface`
that is part of the ACE Agent documentation.

## Usage

To start the bot you can run the following commands in a new terminal window.

```bash
export BOT_PATH=samples/event_interface_tutorial_bot
source deploy/docker/docker_init.sh
docker compose -f deploy/docker/docker-compose.yml up event-bot -d
```
