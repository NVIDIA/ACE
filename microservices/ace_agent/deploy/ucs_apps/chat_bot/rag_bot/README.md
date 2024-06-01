# Retrieval Augmented Generation Bot
This is an example chatbot that showcases Retrieval Augmented Generation (RAG) usecases using [NVIDIA Generative AI Examples](https://github.com/NVIDIA/GenerativeAIExamples/tree/main/RetrievalAugmentedGeneration).  For more details on the sample bot refer [the ACE Agent documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/sample-bots/rag-bot.html).


This directory contains sample UCS application for building helm chart for text to text conversation using the Retrieval Augmented Generation. In following sections, we will add steps for deploying the sample bot using the UCS application.

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

2. Deploy one of the RAG examples by following the instructions in [the GenerativeAIExamples repository](https://github.com/NVIDIA/GenerativeAIExamples/tree/main/RetrievalAugmentedGeneration/examples). A good example to start with is [the NVIDIA API Catalog](https://nvidia.github.io/GenerativeAIExamples/latest/api-catalog.html) example. You can also deploy RAG Server in Kubernetes using [NVIDIA Enterprise RAG LLM Operator](https://docs.nvidia.com/ai-enterprise/rag-llm-operator/24.3.0/index.html).

3. Update `app.yaml` with the deployed RAG Chain Server IP and Port details in `rag-server` component. 
4. Generate the Helm Chart using UCS tools.
    ```
    ucf_app_builder_cli app build app.yaml app-params.yaml
    ```

5. Deploy the generated Helm Chart.
    ```
    helm install ace-agent ucf-app-chat-bot-4.0.0/
    ```

6. Wait for all pods to be ready.
    ```
    watch kubectl get pods
    ```

7. Try out the deployed bot using a sample web frontend application. Get the nodeport for `ace-agent-webapp-deployment-service` using `kubectl get svc` and interact with the bot using the URL `http://<workstation IP>:<Webapp_NodePort>`. 


8. Stop the deployment and remove the persistent volumes.
    ```
    helm uninstall ace-agent

    kubectl delete pvc --all
    ```