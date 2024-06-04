# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

variable "base_config" {
  type = object({
    app_sg_ids               = list(string)
    coturn_sg_ids            = list(string)
    config_bucket            = string
    config_access_policy_arn = string
    keypair = object({
      name = string
    })
    networking = object({
      vpc_id             = string
      public_subnet_ids  = list(string)
      private_subnet_ids = list(string)
    })
  })
}
variable "name" {
  type = string
}
variable "coturn_settings" {
  type = object({
    realm    = string
    username = string
    password = string
  })
  sensitive = true
}

variable "coturn_ami_name" {
  type    = string
  default = null
}