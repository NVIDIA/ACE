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

echo "Verify GPU Operator Ready -- Start"

while [[ "$(kubectl --kubeconfig /etc/kubernetes/admin.conf --namespace nvidia-gpu-operator --no-headers --field-selector="status.phase!=Succeeded,status.phase!=Running" get pods | wc -l)" != 0 ]]; do
  sleep 10
  echo "Waiting for GPU Operator to get READY..."
done

echo "Verify GPU Operator Ready -- End"
