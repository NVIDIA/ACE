# Stock Sample Bot
This is an example chatbot for retrieving live stock prices for the stock of a specified company or organization. This bot also provides answers to queries related to the stock market and stocks. Here, [the Yahoo Finance API](https://pypi.org/project/yfinance/) is used for getting the stock prices of a stock. This bot only answers the questions related to stock prices and the stock market and does not have the ability to answer any off-topic queries. For more details on the sample bot refer [the ACE Agent documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/sample-bots/stock-market-bot.html).


This directory contains sample UCS application for building helm chart for deploying the stock bot with speech support. In following sections, we will add steps for deploying the sample bot using the UCS application.

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

2. The Stock bot uses [the mixtral-8x7b-instruct-v0.1 model](https://build.nvidia.com/mistralai/mixtral-8x7b-instruct) deployed via [the NVIDIA API Catalog](https://build.nvidia.com/explore/discover) as the main model. Get the API key from [the mixtral-8x7b-instruct-v0.1 model card](https://build.nvidia.com/mistralai/mixtral-8x7b-instruct) for trying out the bot and create the Kubernetes secret for passing NVIDIA_API_KEY.
    ```
    cat <<EOF | tee custom-env.txt
    NVIDIA_API_KEY="nvapi-XXX"
    EOF
    kubectl create secret generic custom-env-secrets --from-file=ENV=custom-env.txt
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

5. Try out the deployed bot using a sample web frontend application. Get the nodeport for `ace-agent-webapp-deployment-service` using `kubectl get svc` and interact with the bot using the URL `http://<workstation IP>:<Webapp_NodePort>`. 
    > Note: For accessing the mic on the browser, we need to either convert http to https endpoint by adding SSL validation or update your chrome://flags/ or edge://flags/ to allow  http://<Node_IP>:<Webapp_NodePort> as a secure endpoint.

6. Stop the deployment and remove the persistent volumes.
    ```
    helm uninstall ace-agent

    kubectl delete pvc --all
    ```