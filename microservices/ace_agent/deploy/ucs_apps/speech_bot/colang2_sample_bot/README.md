# Colang 2.0 Sample Bot
This is a sample bot that showcases how to build a simple chat bot with Colang 2.0. The bot provides a chit-chat experience answering questions about NVIDIA (LLM based) and a few examples of guardrailing the conversation (profanity handling, integrating recent information using date time queries). Checkout the example conversation to see what types of interactions the bot supports in [the ACE Agent documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/sample-bots/colang-bot.html).

**What is Colang 2.0?**

Colang 2.0 is the latest iteration of the Colang language and Colang runtime that builds upon the guardrailing and conversational interaction management capabilities of Colang 1.0 and adds support for multimodality at its core. This includes many new concepts such as parallel actions, hierarchical flows, support for UMIM actions and events, and much more. Colang 2.0 is currently available in a preview version with ACE Agent alongside support for Colang 1.0. Colang 2.0 is the best way to create, guardrail, and manage multimodal interactions between users and one (or more) bots.

We will use the ACE Agent event interface which provides an asynchronous, event-based interface to interact with bots written in Colang 2.0. This directory contains sample UCS application for deploying Colang 2.0 bot in event interface with speech support.

## Prerequisites
Before you start using NVIDIA ACE Agent, it’s assumed that you meet the following prerequisites. 
- You have access and are logged into [NVIDIA GPU Cloud (NGC)](https://ngc.nvidia.com/). For more details about NGC, refer to [the NGC documentation](https://docs.nvidia.com/ngc/index.html).
- You have installed [UCS tools](https://docs.nvidia.com/ace/latest/modules/docs/docs/text/UCS_Introduction.html) along with prerequisite setups such as Helm, Kubernetes, GPU Operator, and so on. Refer to UCS tools [developer system](https://docs.nvidia.com/ace/latest/modules/docs/docs/text/UCS_Requirements.html) and [deployment system](https://docs.nvidia.com/ace/latest/modules/docs/docs/text/UCS_Prerequisites.html) prerequisite sections for detailed instructions. 
- You have access to an NVIDIA Volta, NVIDIA Turing, NVIDIA Ampere, NVIDIA Ada Lovelace, or an NVIDIA Hopper Architecture-based GPU. The current version of ACE Agent is only supported on NVIDIA data centers.
- Install the Local Path Provisioner by running the following command if not already done:

    ```
    curl https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.23/deploy/local-path-storage.yaml | sed 's/^  name: local-path$/  name: mdx-local-path/g' | microk8s kubectl apply -f -
    ```

## Deployment

1. Setup the mandatory Kubernetes secrets required for deployment. Setup `ngc-docker-reg-secret` for downloading docker images and `ngc-api-key-secret` for downloading models/resources from NGC. 

    ```
    export NGC_CLI_API_KEY=...

    kubectl create secret docker-registry ngc-docker-reg-secret --docker-server=nvcr.io --docker-username='$oauthtoken' --docker-password="${NGC_CLI_API_KEY}"

    kubectl create secret generic ngc-api-key-secret --from-literal=NGC_CLI_API_KEY="${NGC_CLI_API_KEY}"
    ```

2. The sample bot uses OpenAI gpt-3.5-turbo-instruct as the main model. Configure the OpenAI API key. To create Kubernetes secret, run:

    ```
    export OPENAI_API_KEY=...

    kubectl create secret generic openai-key-secret --from-literal=OPENAI_API_KEY=${OPENAI_API_KEY}
    ``` 
3. Generate the Helm Chart using UCS tools.
    ```
    ucf_app_builder_cli app build app.yaml app-params.yaml
    ```

4. Deploy the generated Helm Chart.
    ```
    helm install ace-agent ucf-app-speech-bot-4.0.0/
    ```

5. Wait for all pods to be ready.
    ```
    watch kubectl get pods
    ```

6. Interact with the bot using [the gRPC Server Sample Client](https://docs.nvidia.com/ace/latest/modules/ace_agent/deployment/sample-clients.html#grpc-server-sample-client) for speech conversation or [the event Sample Client](https://docs.nvidia.com/ace/latest/modules/ace_agent/deployment/sample-clients.html#event-sample-client) for text to text conversations.


7. Stop the deployment and remove the persistent volumes.
    ```
    helm uninstall ace-agent

    kubectl delete pvc --all
    ```