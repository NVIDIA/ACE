#!/bin/bash


echo "Setup TOKKIO Secrets -- Start"

nvcr_io_auth_b64=$(echo -n "\$oauthtoken:${NGC_CLI_API_KEY}" | base64 -w 0)
docker_config_json="{\"auths\":{\"nvcr.io\":{\"auth\":\"${nvcr_io_auth_b64}\"}}}"
docker_config_json_b64=$(echo -n "${docker_config_json}" | base64 -w 0)
ngc_cli_api_key_b64=$(echo -n "${NGC_CLI_API_KEY}" | base64 -w 0)
mlops_aws_access_key_id_b64=$(echo -n "${MLOPS_AWS_ACCESS_KEY_ID}" | base64 -w 0)
mlops_aws_secret_access_key_b64=$(echo -n "${MLOPS_AWS_SECRET_ACCESS_KEY}" | base64 -w 0)
openai_api_key_b64=$(echo -n "${OPENAI_API_KEY}" | base64 -w 0)


cat > custom-env.txt <<EOF
WEATHERSTACK_API_KEY="${WEATHER_API_KEY}"
NGC_ORGANIZATION_ID="${NEMO_LLM_ORG_TEAM}"
EOF

custom_env_file_b64=$(base64 -w 0 < custom-env.txt)

cat <<EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${API_NS}
  labels:
    name: ${API_NS}
EOF

cat <<EOF | kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: ngc-api-key-secret
  namespace: ${API_NS}
data:
  NGC_CLI_API_KEY: ${ngc_cli_api_key_b64}
---
apiVersion: v1
kind: Secret
type: kubernetes.io/dockerconfigjson
metadata:
  name: ngc-docker-reg-secret
  namespace: ${API_NS}
data:
  .dockerconfigjson: ${docker_config_json_b64}
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: mlops-uploader-secret
  namespace: ${API_NS}
data:
  AWS_ACCESS_KEY_ID: ${mlops_aws_access_key_id_b64}
  AWS_SECRET_ACCESS_KEY: ${mlops_aws_secret_access_key_b64}
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: openai-key-secret
  namespace: ${API_NS}
data:
  OPENAI_API_KEY: ${openai_api_key_b64}
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: custom-env-secrets
  namespace: ${API_NS}
data:
  ENV: ${custom_env_file_b64}
EOF

echo "Setup TOKKIO Secrets -- End"