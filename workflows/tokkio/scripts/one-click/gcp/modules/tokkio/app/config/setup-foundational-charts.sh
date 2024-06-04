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

echo "Setup FOUNDATIONAL CHARTS -- Start"

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --cleanup-on-fail \
  --atomic \
  --reset-values \
  --wait \
  --create-namespace \
  --namespace "${FOUNDATIONAL_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  mdx-local-path-provisioner \
  https://helm.ngc.nvidia.com/nvidia/ucs-ms/charts/mdx-local-path-provisioner-0.3.0.tgz

echo "Setup FOUNDATIONAL CHARTS -- End"