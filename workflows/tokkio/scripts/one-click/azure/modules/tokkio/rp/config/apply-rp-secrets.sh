#!/bin/bash


echo "Setup RP Secrets -- Start"

nvcr_io_auth_b64=$(echo -n "\$oauthtoken:${NGC_CLI_API_KEY}" | base64 -w 0)
docker_config_json="{\"auths\":{\"nvcr.io\":{\"auth\":\"${nvcr_io_auth_b64}\"}}}"
docker_config_json_b64=$(echo -n "${docker_config_json}" | base64 -w 0)
cat <<EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/dockerconfigjson
metadata:
  name: ngc-docker-reg-secret
  namespace: default
data:
  .dockerconfigjson: ${docker_config_json_b64}
---
EOF

echo "Setup RP Secrets -- End"
