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
variable "base_config" {
  type = object({
    rp_sg_ids                = list(string)
    config_bucket            = string
    config_access_policy_arn = string
    keypair = object({
      name = string
    })
    networking = object({
      vpc_id            = string
      public_subnet_ids = list(string)
    })
  })
}
variable "instance_suffixes" {
  type = list(string)
}
variable "ngc_api_key" {
  type      = string
  sensitive = true
}
variable "instance_type" {
  type    = string
  default = null
}
variable "instance_data_disk_size_gb" {
  type    = number
  default = null
}
variable "rp_ami_name" {
  type    = string
  default = null
}
variable "rp_settings" {
  type = object({
    chart_org     = string
    chart_team    = string
    chart_name    = string
    chart_version = string
    cns_settings = object({
      cns_version = string
      cns_commit  = string
    })
  })
  default = null
}