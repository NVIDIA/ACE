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

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "virtual_network_address_space" {
  type = string
}

variable "subnet_details" {
  type = list(object({
    identifier            = string
    address_prefix        = string
    type                  = string
    service_endpoints     = list(string)
    nsg_identifier        = string
    associate_nat_gateway = bool
  }))
}

variable "network_security_groups" {
  type = list(object({
    identifier = string
  }))
  default = []
}

variable "network_security_rules" {
  type = list(object({
    nsg_identifier               = string
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    source_port_ranges           = list(string)
    destination_port_range       = string
    destination_port_ranges      = list(string)
    source_address_prefix        = string
    source_address_prefixes      = list(string)
    destination_address_prefix   = string
    destination_address_prefixes = list(string)
    include_nat_as_source        = bool
  }))
  default = []
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}