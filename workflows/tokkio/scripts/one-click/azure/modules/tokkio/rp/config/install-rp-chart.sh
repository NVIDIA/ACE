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

echo "Setup RP Chart -- Start"

echo 'rProxySpec:
  nodeSelector:
    type: rp
  tolerations:
  - key: "rproxy-node"
    operator: "Exists"
  publicInterfaceName: "eth0"
  privateInterfaceName: "eth0"
  imagePullSecrets:
  - name: ngc-docker-reg-secret
  checkIPUri: "http://checkip.amazonaws.com"' > /tmp/rproxy-override-values.yml 

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --cleanup-on-fail \
  --reset-values \
  --create-namespace \
  --namespace default \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  --values /tmp/rproxy-override-values.yml \
  rp-app \
  "${RP_CHART_URL}"

echo "Setup RP Chart -- End"