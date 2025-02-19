# Gaming Non-Playing Character (NPC) Bots
The NPC sample bots showcase how you can:
- build LLM driven Natural Language Understanding (NLU) and Natural Language Generation (NLG) capabilities for non-playable characters in a game.
- provide game-stage specific context to the Chat Engine at runtime and utilize that context to change the behavior of NPC's.

There are two [sample NPC bots](https://docs.nvidia.com/ace/latest/modules/ace_agent/sample-bots/gaming-npc-bot.html) provided as part of the NVIDIA ACE Agent release. Each bot corresponds to one unique character in the game, having a unique personality, and backstory. You can find the backstories for the two characters in the `samples/jin/bot_config.yaml` and `samples/elara/bot_config.yaml` files respectively. You can change this backstory, if needed, based on the character you are designing. We can deploy both the bots in a single Chat Engine instance and try them out together interactively. These bots use [NVIDIA API Catalog’s  mixtral-8x7b-instruct](https://build.nvidia.com/mistralai/mixtral-8x7b-instruct) as the main model. 


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

2. The NPC bots uses nemotron-mini-4b-instruct from the NVIDIA API Catalog. Configure the NVIDIA API key. To create Kubernetes secret, run:

    ```
    export NVIDIA_API_KEY=...

    kubectl create secret generic nvidia-api-key-secret --from-literal=NVIDIA_API_KEY=${NVIDIA_API_KEY}
    ```

3. Generate the Helm Chart using UCS tools.
    ```
    ucf_app_builder_cli app build app.yaml app-params.yaml
    ```

4. Deploy the generated Helm Chart.
    ```
    helm install ace-agent ucf-app-speech-bot-4.1.0/
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