#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

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
