NVIDIA ACE
--------

NVIDIA ACE is a suite of technologies that help developers bring digital humans to life with generative AI. ACE NIMs are microservices designed to run in the cloud or on PC.

![](https://lh7-us.googleusercontent.com/FJKnZYOQX34lHQ_OccHOvSXFfsFg3RyY1LWgg9_s5NA1RrQr4XH8cA5T3CvuQmysig74EpxQFbOwN4OP-CpQgYNGbjIpC6ior7YlhYPdqMI95fP-_Kv5dkZB_RSegAQ-m6-yzN2n-uwFjDAZB1rlPKQ)

On this Git repo, you will find samples and reference applications using ACE NIMs and microservices.  However, these microservices can be obtained through an evaluation license of NV AI Enterprise(NVAIE) through NGC.

1. [Try NIM For Digital Human](https://build.nvidia.com/explore/gaming)
2. [Get NVIDIA AI Enterprise](https://docs.nvidia.com/ai-enterprise/latest/quick-start-guide/index.html#getting-your-nvidia-grid-software)
3. [Download ACE Microservices](https://catalog.ngc.nvidia.com/?filters=&orderBy=scoreDESC&query=ace&page=&pageSize=)


ACE Technologies
------
|                    Technology                   |                                Description                              |          Software   Support        |     Cloud   Deployment    |     Windows   Deployment    |
|:-----------------------------------------------:|:-----------------------------------------------------------------------:|:----------------------------------:|:-------------------------:|:---------------------------:|
|     Riva      Automatic Speech   Recognition    |                            Speech   -&gt; Text                          |        NVIDIA   AI Enterprise      |              X            |         Coming   Soon       |
|      Riva      Neural Machine   Translation     |                            Text   Translation                           |        NVIDIA   AI Enterprise      |              X            |                             |
|             Riva      Text-to-Speech            |                            Text   -&gt; Speech                          |        NVIDIA   AI Enterprise      |              X            |         Coming   Soon       |
|                    Audio2Face                   |           Audio   -&gt; Blendshapes      for   Facial Lip-sync          |        NVIDIA   AI Enterprise      |              X            |         Coming   Soon       |
|                     AnimGraph                   |                          Animation   controller                         |        NVIDIA   AI Enterprise      |              X            |                             |
|             Omniverse RTX Rendering Microservice           |                     Omniverse   Based Pixel Streamer                    |        NVIDIA   AI Enterprise      |              X            |                             |
|                     ACE Agent                   |                Conversational   Controller, RAG Workflows               |        NVIDIA   AI Enterprise      |              X            |                             |
|           Maxine Speech   Live Portrait         |                    2D   Picture Lipsync and Animation                   |     Early   Access   Evaluation    |              X            |                             |
|                Nemotron-3 4.5B SLM              |                          Small   Language Model                         |      Early   Access Evaluation     |        Coming   Soon      |               X             |
|             Gaming Reference Workflow           |                    Audio2Face   Unreal Engine Examples                  |          Example   Workflow        |              X            |         Coming   Soon       |
|       Customer Service Reference   Workflow     |     Full   reference workflow of customer service and kiosk usecases    |       Example   Workflow           |              X            |                             |


The Key Benefits of ACE
--------

### State-of-the-Art Models and Microservices

NVIDIA pre-trained models provide industry-leading quality and real-time performance.

### Safe and Consistent Results

AI models  trained on commercially safe, responsibly licensed data. Fine-tuning and guardrails enable accurate, appropriate, and on-topic results no matter the user's input.

### Flexible Deployment Options

Handle inference through any public or private cloud, Windows PC, or a mix of both.

## Digital Human Workflows

Developers can leverage ACE to build their own digital human solutions from the ground up, or use NVIDIA's suite of domain-specific AI workflows for next-generation non-playable game characters (NPCs), interactive digital assistants for customer service, and digital avatars for real-time communication.

### Gaming Characters

NVIDIA Kairos Sample showcases an easy to use Unreal Engine project using the Audio2Face microservice. This sample shows how to connect Audio2Face to Metahuman and configure the Audio2Face microserivce. 

[Learn More About ACE NIMs for Gaming](https://build.nvidia.com/explore/gaming)

### Customer Service

NVIDIA Tokkio is a digital assistant workflow built with ACE, bringing AI-powered customer service capabilities to healthcare, financial services, and retail. It comes to life using state-of-the-art real-time language, speech, and animation generative AI models alongside retrieval augmented generation (RAG) to convey specific and up-to-date information to customers.

[Learn More Tokkio Customer Service Workflow](https://developer.nvidia.com/nvidia-omniverse-platform/ace/tokkio-showcase)

Documentation and Tutorials
-------------
Full ACE [developer documenation](https://docs.nvidia.com/ace/latest/index.html)

| Component | Documentation | Video/Tutorial |
| ------ | ------ | ------ |
|      Getting Started  |        | [NVIDIA Docker Setup](https://youtu.be/2uWXeIol468), [Install Kubernetes](https://www.youtube.com/watch?v=ACIkyiWglW4) |
|     NVIDIA UCS   | [Documentation](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/ucs-ms/resources/ucs_tools/version) ||
|NVIDIA Audio2Face| [Documentation](https://docs.nvidia.com/ace/latest/modules/a2f-docs/index.html) | Coming soon! |
|NVIDIA Riva ASR| [Documentation](https://docs.nvidia.com/deeplearning/riva/user-guide/docs/asr/asr-overview.html)|Coming soon! |
|NVIDIA Riva TTS| [Documentation](https://docs.nvidia.com/deeplearning/riva/user-guide/docs/tts/tts-overview.html)|Coming soon! |
|NVIDIA Riva NMT|[Documentation](https://docs.nvidia.com/deeplearning/riva/user-guide/docs/translation/translation-overview.html) |Coming soon! |
|NVIDIA ACE Agent Microservices|[Documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/index.html)|Coming soon! |
|NVIDIA Maxine Live Portrait|[Documentation](https://registry.ngc.nvidia.com/orgs/eevaigoeixww/teams/live-portrait-ms/resources/live_portrait_user_guide)|Coming soon! |
|NVIDIA Avatar Configurator & Avatar Customization|[Documentation](https://docs.nvidia.com/ace/latest/modules/avatar_customization/Avatar_Configurator.html)|Coming soon! |
|NVIDIA Animation Graph Microservice|[Documentation](https://docs.nvidia.com/ace/latest/modules/animation_graph_microservice/index.html)|Coming soon! |
|NVIDIA Omniverse Renderer Microservice|[Documentation](https://docs.nvidia.com/ace/latest/modules/omniverse_renderer_microservice/index.html)|Coming soon! |

### Example Workflows

| Example | Description | Video |
| ------ | ------ | ------ |
|     Text-to-Gesture   |   Text-to-Gesture using A2X & Animation Graph Microservices     | [Creation of Basic Sentiment Analysis Utility](https://www.youtube.com/watch?v=g3Vb7EhlEUA),  [Connecting all Microservices in UCF](https://www.youtube.com/watch?v=TP4RD-T0GOI),  [Deployment & App Execution](https://www.youtube.com/watch?v=EHyga9smaSA)|
|    Reallusion Character    |   Exporting Character in Reallusion Character Creator + Audio2Face     | [Exporting Character from Reallusion Character Creator & Preparing Character in Audio2Face](https://www.youtube.com/watch?v=_Vkiup06lYQ), [Setup, streaming through a Reference App & Fine Tuning](https://www.youtube.com/watch?v=3xBhOKHbrFU)|
|      Stylised Avatar  |    Building Stylised Avatar Pipeline with ACE Components    | [Making & Animating a Stylised 3D Avatar From Text Inputs](https://www.youtube.com/watch?v=cnyy0mlL8C0), [Make Vincent Rig Compatible for UE5 & A2X LiveLink](https://www.youtube.com/watch?v=2MgzVluShtc), [Make Vincent Blueprint Receive A2X Animation Data](https://www.youtube.com/watch?v=fpthK6WHjX8), [Create Python App to Generate Audio from Text & Animate Vincent](https://www.youtube.com/watch?v=g14c2gcbowM)|


License
-------

Github - [Apache 2](https://www.apache.org/licenses/LICENSE-2.0.txt)

ACE NIMs and NGC Microservices - [NVIDIA AI Product License](https://www.nvidia.com/en-us/data-center/products/nvidia-ai-enterprise/eula/)