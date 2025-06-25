# SPDX-FileCopyrightText: Copyright (c) <year> NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

settings = {
    "namespace": "app", # kubernetes namespace which your app is deployed
    "ace_controller": { 
        "http_url": "http://<ace-controller-host>:<ace-controller-port>", # local ACE controller HTTP endpoint to receive the SDR add/remove calls emulated by this tool
        "ws_url": "ws://<ace-controller-host>:<ace-controller-port>/ws", # local ACE controller websocket endpoint to accept websocket connection from Tokkio UI MS from the kubernetes cluster
    },
    "env_file": {
        "target": "../src/llm-rag/.env", # output ENV file containing the user-defined ENV + auto-generated ENV.  To be used by the local Ace controller
        "src": ".env" # source ENV file containing all the user-defined ENV
    },
}

######################################################################################################################################################################
############### Note: You should not need to change the configuration beyond this line unless you want to experiment with some advanced customizations ###############
######################################################################################################################################################################

redis_settings = {
    "connection_retry": 10, # max number of attempts of Redis reconnection
    "url_env": "REDIS_URL", # ENV for Redis stream URL from the k8 Redis Timeseries POD
    "vst_event_key": "vst_events" # pipeline triggering event Redis stream key
}

# services to be converted to NodePort with dynamic por##t assignment
node_port_settings = { 
    "a2f-a2f-deployment-a2f-service": [
        {"env": "A2F_GRPC_URL", "url": "<host>:<port>", "ports": {"port": 50010, "targetPort": 50010}}
    ],
    "riva-speech": [
        {"env": "RIVA_SERVER_URL", "url": "<host>:<port>", "ports": {"port": 50051, "targetPort": 50051}}
    ],
    "ia-animation-graph-microservice": [
        { "env": "ANIMGRAPH_URL", "url": "http://<host>:<port>", "ports": {"port": 8020, "targetPort": 8020}},
        { "env": "ANIMGRAPH_GRPC_URL", "url": "<host>:<port>", "ports": {"port": 51000, "targetPort": 51000}}
    ],
    "redis-timeseries": [
        {"env": redis_settings["url_env"], "url": "redis://<host>:<port>", "ports": {"port": 6379, "targetPort": 6379}}
    ],
}

# The ENV specified in the deployment list below will be update from the kubernetes deployment (unique ENV only)
deployments = { 
    "ace-controller-sdr-envoy-sdr-deployment": {
        "container": "agent-container",
        "env_list": [
            {
                "name": "WDM_MSG_KEY",
                "value": "dummy"
            }
        ]
    },
    "tokkio-ui": {
        "container": "ui",
        "env_list": [
            {
                "name": "ACE_CONTROLLER_WEBSOCKET_ENDPOINT",
                "value": settings['ace_controller']['ws_url']
            }
        ]
    }
}

# The ADD / REMOVE endpoints from the list of services below will be called based on vst_events to simulate SDR operation
services = { 
    "ace-controller-ace-controller-deployment-ace-controller-service": {
        "url": settings['ace_controller']['http_url'], # url_key can also be used to reference url specified in the ENV
        "sdr_op": {
            "camera_streaming": "stream/add",
            "camera_remove": "stream/remove"
        },
    },
}
