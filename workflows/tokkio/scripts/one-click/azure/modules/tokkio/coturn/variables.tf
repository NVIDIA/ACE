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
    resource_group = object({
      name = string
    }),
    networking = object({
      region              = string
      coturn_vm_subnet_id = string
    }),
    keypair = object({
      public_key = string
    }),
    config_storage_account = object({
      id   = string
      name = string
      reader_identity = object({
        id        = string
        client_id = string
      })
      reader_access = object({
        id = string
      })
    })
  })
}
variable "turnserver_realm" {
  type = string
}
variable "turnserver_username" {
  type      = string
  sensitive = true
}
variable "turnserver_password" {
  type      = string
  sensitive = true
}
variable "coturn_vm_image_version" {
  type    = string
  default = null
}