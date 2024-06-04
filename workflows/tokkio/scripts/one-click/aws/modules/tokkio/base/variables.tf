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

variable "cidr_block" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "dev_access_ipv4_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "dev_access_ipv6_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "user_access_ipv4_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "user_access_ipv6_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "base_domain" {
  type = string
}

variable "bastion_ami_name" {
  type    = string
  default = null
}