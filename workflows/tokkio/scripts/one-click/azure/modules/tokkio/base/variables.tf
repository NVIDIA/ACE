# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "virtual_network_address_space" {
  type = string
}
variable "ssh_public_key" {
  type = string
}
variable "dev_source_address_prefixes" {
  type = list(string)
}
variable "user_source_address_prefixes" {
  type = list(string)
}
variable "dns_and_certs_configs" {
  type = object({
    resource_group = string
    dns_zone       = string
    wildcard_cert  = string
  })
}

variable "bastion_vm_image_version" {
  type    = string
  default = null
}