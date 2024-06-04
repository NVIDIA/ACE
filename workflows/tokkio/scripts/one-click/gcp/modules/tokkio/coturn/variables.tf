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
    vpc = object({
      network           = string
      coturn_subnetwork = string
    })
    region = string
    zone   = string
    config_bucket = object({
      name = string
    })
    instance_tags = object({
      coturn = list(string)
    })
    ssh_public_key = string
  })
}
variable "coturn_settings" {
  type = object({
    realm    = string
    username = string
    password = string
  })
  sensitive = true
}
variable "coturn_instance_image" {
  type    = string
  default = null
}