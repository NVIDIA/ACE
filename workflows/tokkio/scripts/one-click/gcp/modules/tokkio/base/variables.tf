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
variable "location" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "network_cidr_range" {
  type = string
}
variable "ssh_public_key" {
  type = string
}
variable "dev_access_cidrs" {
  type = list(string)
}
variable "user_access_cidrs" {
  type = list(string)
}
variable "bastion_instance_image" {
  type    = string
  default = null
}
variable "ui_bucket_location" {
  type = object({
    location         = string
    region           = string
    alternate_region = string
  })
}