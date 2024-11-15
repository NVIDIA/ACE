# Large Language Model (LLM) Bot
This is an example chatbot that showcases bot usecase with Large Language Model (LLM). 


This directory contains sample UCS application for building helm chart for text to text conversation using the LLMs. In following sections, we will add steps for deploying the sample bot using the UCS application.

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

2.  The sample bot uses Meta's llama3-8b-instruct as the main model. Configure the NVIDIA API key to use hosted NIM model, you can use dummy value otherwise. To create Kubernetes secret, run:

    ```
    export NVIDIA_API_KEY=...

    kubectl create secret generic nvidia-api-key-secret-key-secret --from-literal=NVIDIA_API_KEY=${NVIDIA_API_KEY}
    ```

3. Generate the Helm Chart using UCS tools.
    ```
    ucf_app_builder_cli app build app.yaml app-params.yaml
    ```

4. Add the LLM url under `./ucf-app-chat-bot-4.1.0/charts/ace-agent-chat-engine/files/config_dir/actions.py`
    ```
    BASE_URL = "http://0.0.0.0:8010/v1" # Set to "https://integrate.api.nvidia.com/v1" for using hosted NIM models and provide API key using NVIDIA_API_KEY env variable
    ```

5. Deploy the generated Helm Chart.
    ```
    helm install ace-agent ucf-app-chat-bot-4.1.0/
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
