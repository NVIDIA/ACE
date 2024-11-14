# ACE Agent

ACE Agent is a collection of microservices to help build LLM driven scalable and customizable Conversational AI Agents. It offers a complete workflow to build and deploy virtual agents that can support multi-turn and multi-user contextual conversation flow. It provides connectivity between AI skills like NVIDIA Riva Speech AI, NVIDIA ACE Avatar AI & Vision AI, usecase specific custom plugins, and user interfaces through efficient system integration and composable dialog management.

Some of the major benefits that ACE Agent provides are:

- **In-built LLM integration** - ACE Agent works with large language models (LLM) out-of-the-box and provides a hook to connect with the LLM model of your choice.

- **On-premise model deployment** - ACE Agent supports on premise deployment of both ACE Agent models as well as other community and custom models. NVIDIA NIM for LLMs brings state of the art GPU accelerated large language model serving. Using NIM, you can deploy an LLM of your choice on premise and use it with ACE Agent.

- **Highly customizable** - ACE Agent allows you to completely customize the behavior of the bot based on your usecase using Colang. It even allows you to integrate agents and bots built using LangChain or similar frameworks in the ACE Agent pipeline for building multi-model use cases.

- **RAG** - ACE Agent allows easy integration with Retrieval Augmented Generation (RAG) workflows to support building agents using existing knowledge documents with minimal efforts.

- **Low latency** - ACE Agent uses NVIDIA TensorRT optimized models, NVIDIA Triton Inference Server for model deployment, and optimized chat controller to ensure low latency and high throughput bot interactions.

For more details, check [the ACE Agent Documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/index.html).

## UCS Microservices

ACE Agent provides Kubernetes deployment using NVIDIA Unified Cloud Services (UCS) Tools. NVIDIA Unified Cloud Services Tools (UCS Tools) is a low-code framework for developing cloud-native, real-time, and multimodal AI applications. The NVIDIA ACE Agent releases includes the following UCS microservices:

| Microservice Name  | Version  | Description|
|---|---|---|
| ucf.svc.ace-agent.chat-controller  | 4.1.0  | The Chat Controller orchestrates the end-to-end pipeline for a speech IO based Conversational AI Agents. The Chat Controller creates a pipeline consisting of Automatic Speech Recognition (ASR), Chat Engine, Text-To-Speech (TTS), NVIDIA Omniverse Audio2Face Client, and manages the flow of audio or text data between these modules. |
| ucf.svc.ace-agent.chat-engine  | 4.1.0  | The Chat Engine is microservice built on top of the NVIDIA NeMo Guardrails and allow you to design conversational flow using Colang. |
| ucf.svc.ace-agent.nlp-server  | 4.1.0  | The ACE Agent NLP server exposes unified RESTful interfaces for integrating various NLP models and tasks in ACE Agent pipeline. |
| ucf.svc.ace-agent.plugin-server  | 4.1.0  | The Plugin server allows us to add use case/domain specific business logic such as getting weather data from weather APIs in the bots. The Plugin server can also allow you to integrate your own agent built using LangChain or LlamaIndex or any other framework in ACE Ecosystem. |
| ucf.svc.ace-agent.web-app | 4.1.0  | The sample frontend application for trying out bot deployed using ACE agent with voice capture and playback support as well as with text input-output support.  |


You can easily create your own custom application Helm chart using ACE Agent microservices with UCS applications. The ACE Agent Quick Start package comes with a number of UCS applications for sample bots which can be found in the [./deploy/ucs_apps/](./deploy/ucs_apps/) directory.

## Samples

The ACE Agent Quick Start package comes with a number of sample bots which can be found in the [./samples/](./samples/) directory. The sample bots are built for different use cases and industries and showcases various features of ACE Agent. 

For more details refer [Sample Bots section](https://docs.nvidia.com/ace/latest/modules/ace_agent/index.html#sample-bots) in the ACE Agent Documentation.