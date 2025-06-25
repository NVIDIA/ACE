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

import asyncio
import redis.asyncio as redis
import httpx 
import json
import re
import signal
import os
from kubernetes import client, config
from typing import Optional
from redis.exceptions import ConnectionError, RedisError
from loguru import logger
from config import settings, redis_settings, services, node_port_settings, deployments

class TokkioDevTool:
    def __init__(self, namespace="default"):
        config.load_kube_config() 
        self.app_api = client.AppsV1Api()
        self.core_api = client.CoreV1Api()
        self.ace_sdr_replicas = None
        self.redis_client = None
        self.interrupted = False
        self.cluster_ip = None
        self.namespace = namespace
        self.stop_event = asyncio.Event()
        self.deployment_env_dict = {}

    def get_k8_cluster_ip(self):
        nodes = self.core_api.list_node().items
        for node in nodes:
            for address in node.status.addresses:
                if address.type == "InternalIP":
                    self.cluster_ip = address.address

    def update_k8_deployment_env(self, deployment_name, container_name, env_name, env_value=None):
        deployment = self.app_api.read_namespaced_deployment(deployment_name, self.namespace)
        
        for container in deployment.spec.template.spec.containers:
            if container.name == container_name:
                for env_var in container.env:
                    if env_var.name == env_name:
                        if env_value is not None: # for new env value assignment
                            self.deployment_env_dict[env_var.name] = env_var.value or ""
                            env_var.value  = env_value
                        else: # for revert on exit
                            env_var.value = self.deployment_env_dict[env_var.name]
                        self.app_api.patch_namespaced_deployment(deployment_name, self.namespace, deployment)
                        logger.info(f"Updated ENV {env_name} in {deployment_name} to {env_var.value}")

    def patch_service_to_node_port(self, env_file_src_handler=None, env_file_target_handler=None): 
        content = env_file_src_handler.read() if env_file_src_handler is not None else ""
        for service_name, node_port_setting in node_port_settings.items():
            for node_port_profile in node_port_setting:
                env_name = node_port_profile["env"]
                patch = {
                    "spec": {
                        "type": "NodePort",
                        "ports": [node_port_profile["ports"]]
                    }
                }
                self.core_api.patch_namespaced_service(name=service_name, namespace=self.namespace, body=patch)
                logger.info(f"Service '{service_name}' updated to NodePort")
                service = self.core_api.read_namespaced_service(service_name, self.namespace)
                for port in service.spec.ports:
                    container_port = node_port_profile["ports"]["port"]
                    if port.port == container_port:
                        env_value = node_port_profile["url"].replace("<host>", str(self.cluster_ip)).replace("<port>", str(port.node_port))
                        logger.info(f"Setting ENV {env_name}={env_value}")
                        os.environ[env_name] = env_value
                        content += f"\n{env_name}={env_value}"
        if env_file_target_handler is not None:
            env_file_target_handler.write(content)
            logger.info(f"Writing to {env_file_target_handler.name}...\n{content}")

    async def cleanup(self):
        try:
            self.interrupted = True
            for service_name, node_port_setting in node_port_settings.items():
                self.core_api.patch_namespaced_service(name=service_name, namespace=self.namespace, body={"spec": {"type": "ClusterIP"}})
                logger.info(f"reverted {service_name} back to clusterIP")
            # if ace_sdr_replicas and ace_sdr_replicas > 0:
            #     scale_deployment(deployment_name=deployments["ace"], replicas=ace_sdr_replicas)
            #     logger.info(f"scale sdr back to {ace_sdr_replicas}")
            
            for deployment, deployment_setting in deployments.items():
                for env in deployment_setting["env_list"]:
                    self.update_k8_deployment_env(deployment_name=deployment, container_name=deployment_setting["container"], env_name=env["name"])
            logger.info("clean up completed")
        except Exception as e:
            logger.error(f"Error during clean up: {e}")

    def scale_deployment(self, deployment_name, replicas):
        global ace_sdr_replicas
        deployment = self.app_api.read_namespaced_deployment(deployment_name, self.namespace)
        ace_sdr_replicas = deployment.spec.replicas
        deployment.spec.replicas = replicas
        self.app_api.patch_namespaced_deployment(deployment_name, self.namespace, deployment)
        logger.info(f"Scaled {deployment_name} from {ace_sdr_replicas} to {replicas} replicas.")

    async def handle_pipeline_trigger_event(self, last_id: str = "$"):
        assert redis_settings.get("url_env", None) is not None, "Redis url env is not defined"
        redis_url = os.getenv(redis_settings["url_env"], None)
        
        retries = 0
        while retries < redis_settings["connection_retry"]:
            try:
                self.redis_client = redis.from_url(redis_url, decode_responses=True) # without decode_responses=True, message will be binary
                await self.redis_client.ping()
                logger.info(f"connected to redis ==> {redis_url}")
                break
            except (ConnectionError, OSError) as e:
                logger.error(f"Redis connection failed (attempt {retries+1}/{redis_settings['connection_retry']}): {e}")
                await asyncio.sleep(2)
                retries += 1
        if retries == redis_settings["connection_retry"]:
            raise RuntimeError("Failed to connect to Redis after multiple attempts.")

        try:
            while not self.stop_event.is_set():
                xread_task = asyncio.create_task(self.redis_client.xread(streams={redis_settings["vst_event_key"]: last_id}, count=10, block=0))
                stop_task = asyncio.create_task(self.stop_event.wait())
                
                done, pending = await asyncio.wait({xread_task, stop_task}, return_when=asyncio.FIRST_COMPLETED)
                
                if xread_task in done:
                    x_read_result = xread_task.result()
                    if x_read_result:
                        for stream, messages in x_read_result:
                            for message_id, message in messages:
                                logger.info(f"Received message ID: {message_id}, Data: {message}")
                                last_id = message_id  # Update last ID to avoid re-reading messages
                                trigger_payload = json.loads(message["sensor.id"])
                                if "change" in trigger_payload["event"] and trigger_payload["event"]["change"] in services['ace-controller-ace-controller-deployment-ace-controller-service']['sdr_op']:
                                    trigger_payload["event"]["camera_url"] = re.sub(r'(?<=rtsp://)(.*?)(?=/webrtc/)', f"{self.cluster_ip}:30554", trigger_payload["event"]["camera_url"])
                                    event_type = trigger_payload["event"]["change"]
                                    await self.trigger_pipeline(event_type=event_type, payload=trigger_payload)
                                else:
                                    logger.warning(f"Ignore unknown message: {message}")
                for task in pending:
                        task.cancel()
        except asyncio.CancelledError:
            logger.warning("Read stream task cancelled.")            
        except ConnectionError as e:
            logger.error(f"Redis connection error: {e}")
        except Exception as e:
            logger.error(f"Error reading stream: {e}")
        finally:
            await self.close_redis_client()
            await self.cleanup()

    async def close_redis_client(self):
        if self.redis_client:
            try:
                await self.redis_client.aclose()
                logger.info("Redis connection closed.")
            except (ConnectionError, RedisError) as e:
                logger.error(f"Error closing Redis: {e}")
            self.redis_client = None

    async def trigger_pipeline(self, event_type: str, headers: Optional[dict] = {}, payload: Optional[dict] = {}):
        async with httpx.AsyncClient() as client:
            for service, services_setting in services.items():
                assert services_setting.get("url", None) or services_setting.get("url_key", None) is not None, f"http url for service {service} is not defined"
                logger.info(f"Making http call to simulate {service}'s SDR call for {event_type}")
                try:
                    url =  services_setting["url"] if services_setting.get("url", None) is not None else os.getenv(services_setting["url_key"], None)
                    assert url is not None, f"URL for service {service} is not define"
                    uri = f"{url}/{services_setting["sdr_op"].get(event_type, None)}"
                    assert uri is not None, f"sdr operation for {url} is not define"
                    logger.info(f"uri => {uri} => {headers}\npayload => {payload}")
                    response = await client.post(uri, json=payload, headers=headers)
                    logger.info(f"Response: {response.status_code}, {response.text}")
                except Exception as e:
                    logger.error(f"HTTP Request failed: {e}")

async def main():
    dev_tool = TokkioDevTool(settings["namespace"])
    dev_tool.get_k8_cluster_ip()
    if settings["env_file"]:
        logger.info(f"Creating ENV file at {os.path.abspath(settings["env_file"]["target"])}")
        env_src = os.path.expanduser(settings["env_file"]["src"])
        env_target = os.path.expanduser(settings["env_file"]["target"])
        with open(env_src, "r") as env_file_src:
            with open(env_target, "w") as env_file_target:
                dev_tool.patch_service_to_node_port(env_file_src_handler=env_file_src, env_file_target_handler=env_file_target)
    
    def shutdown_handler():
        logger.info("\nReceived CTRL+C. Shutting down...")
        dev_tool.stop_event.set()  # Signal reader to stop
    
    for deployment, deployment_setting in deployments.items():
        for env in deployment_setting["env_list"]:
            dev_tool.update_k8_deployment_env(deployment_name=deployment, container_name=deployment_setting["container"], env_name=env["name"], env_value=env["value"])
        
    asyncio.get_event_loop().add_signal_handler(signal.SIGINT, shutdown_handler)
    asyncio.get_event_loop().add_signal_handler(signal.SIGTERM, shutdown_handler)
    asyncio.get_event_loop().add_signal_handler(signal.SIGHUP, shutdown_handler)
    await dev_tool.handle_pipeline_trigger_event()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        logger.error(f"Error occur: {e}")