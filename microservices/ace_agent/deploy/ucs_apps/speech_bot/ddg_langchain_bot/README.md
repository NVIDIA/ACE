# DuckDuckGo LangChain Sample Bot
This is an example chatbot that showcases a [LangChain](https://www.langchain.com/) agent that uses conversation history and [the DuckDuckGo tool](https://python.langchain.com/v0.1/docs/integrations/tools/ddg/) to answer questions. It first rephrases the question based on the conversation history, poses the rephrased question to DuckDuckGo, and generates a final answer based on the DuckDuckGo output. It relies on a custom plugin endpoint which streams the response from the agent. It uses an [OpenAI](https://openai.com/) chat model for rephrasing and final response formation. For more details on the sample bot refer [the ACE Agent documentation](https://docs.nvidia.com/ace/latest/modules/ace_agent/sample-bots/duckduckgo-langchain-bot.html).

In following sections, we will add steps for deploying the sample bot using the UCS application.

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

2. The sample bot uses OpenAI `gpt-3.5-turbo-instruct` as the main model. Configure the OpenAI API key. To create Kubernetes secret, run:

    ```
    export OPENAI_API_KEY=...

    kubectl create secret generic openai-key-secret --from-literal=OPENAI_API_KEY=${OPENAI_API_KEY}
    ```

3. The LangChain plugin requires additional packages to be installed in the Plugin server container. 
    - For building the plugin server custom container, change directory to ACE Agent microservices root directory.
    
    - Change directory to Build a custom Dockerfile by copying the requirements from `samples/ddg_langchain_bot/plugins/requirements_dev.txt` into `deploy/docker/dockerfiles/plugin_server.Dockerfile`.

        ```
            ##############################
            # Install custom dependencies 
            ##############################
            RUN pip3 install \
                langchain==0.1.1 \
                langchain-community==0.0.13 \
                langchain-core==0.1.12 \
                duckduckgo-search==5.3.1b1
        ```
    
        > Note: If you see a crash in the Plugin server or an issue with fetching a response from DuckDuckGo, try using a more recent duckduckgo-search version.
        
    - Build the container and push to the NGC Docker registry.
        ```
        # Set required environment variables for docker-compose.yaml
        source deploy/docker/docker_init.sh

        # Build custom plugin server docker image
        docker compose -f deploy/docker/docker-compose.yml build plugin-server

        # Retag docker image and push to NGC docker registry
        docker tag docker.io/library/plugin-server:4.1.0 <CUSTOM_DOCKER_IMAGE_PATH>:<VERSION>

        docker push <CUSTOM_DOCKER_IMAGE_PATH>:<VERSION>
        ```
        If you want to use a different Docker registry, update `imagePullSecrets` in `langchain-app/app.yaml`.


4. Override the Plugin server image using `langchain-app/params.yaml`.
    ```
    plugin-server:
        pluginConfigPath: "plugin_config.yaml"
        applicationSpecs:
            deployment:
            containers:
                container:
                image:
                    repository: <CUSTOM_DOCKER_IMAGE_PATH>
                    tag: <VERSION>
    ```

4. Generate the Helm Chart using UCS tools.
    ```
    ucf_app_builder_cli app build app.yaml app-params.yaml
    ```

5. Deploy the generated Helm Chart.
    ```
    helm install ace-agent ucf-app-speech-bot-4.1.0/
    ```

6. Wait for all pods to be ready.
    ```
    watch kubectl get pods
    ```

7. Try out the deployed bot using a sample web frontend application. Get the nodeport for `ace-agent-webapp-deployment-service` using `kubectl get svc` and interact with the bot using the URL `http://<workstation IP>:<Webapp_NodePort>`. 

    > Note: For accessing the mic on the browser, we need to either convert http to https endpoint by adding SSL validation or update your chrome://flags/ or edge://flags/ to allow  http://<Node_IP>:<Webapp_NodePort> as a secure endpoint. 

8. Stop the deployment and remove the persistent volumes.
    ```
    helm uninstall ace-agent

    kubectl delete pvc --all
    ```