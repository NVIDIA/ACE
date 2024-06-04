# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "private_ips" {
  value = [for instance_suffix in var.instance_suffixes : module.api_vm[instance_suffix].private_ip]
}
output "ui_endpoint" {
  value = local.ui_endpoint
}
output "api_endpoint" {
  value = local.api_endpoint
}
output "elasticsearch_endpoint" {
  value = "https://${local.elastic_domain}"
}
output "kibana_endpoint" {
  value = "https://${local.kibana_domain}"
}
output "grafana_endpoint" {
  value = "https://${local.grafana_domain}"
}