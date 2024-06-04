# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "bastion_infra" {
  value = {
    public_ip  = module.base.bastion_vm.public_ip
    private_ip = module.base.bastion_vm.private_ip
  }
}

output "coturn_infra" {
  value = one(module.coturn) != null ? {
    public_ip  = nonsensitive(one(module.coturn)["public_ip"])
    private_ip = nonsensitive(one(module.coturn)["private_ip"])
    port       = nonsensitive(one(module.coturn)["port"])
  } : null
}

output "rp_infra" {
  value = one(module.rp)
}

output "app_infra" {
  value = {
    private_ips            = module.app.private_ips
    api_endpoint           = module.app.api_endpoint
    ui_endpoint            = module.app.ui_endpoint
    elasticsearch_endpoint = module.app.elasticsearch_endpoint
    kibana_endpoint        = module.app.kibana_endpoint
    grafana_endpoint       = module.app.grafana_endpoint
  }
}