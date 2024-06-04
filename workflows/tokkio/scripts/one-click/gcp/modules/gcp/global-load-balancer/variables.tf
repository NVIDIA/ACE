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
variable "default_service" {
  type = string
}
variable "ssl_certificates" {
  type = list(string)
}
variable "https_port_range" {
  type = string
}
variable "http_port_range" {
  type = string
}

# variable "host_rules" {
#   type = map(object({
#     hosts = list(string)
#     path_matcher = string
#   }))
#   default = {}
# }

# variable "path_matchers" {
#   type = map(object({
#     default_service = string
#     path_rules = object({
#       paths   = list(string)
#       service = string
#     })
#   }))
#   default = {}
# }

variable "host_rules" {
  type = list(object({
    hosts        = list(string)
    path_matcher = string
  }))
  default = []
}

variable "path_matchers" {
  type = list(object({
    name            = string
    default_service = optional(string)
    path_rules = list(object({
      paths   = list(string)
      service = optional(string)
    }))
  }))
  default = []
}

variable "service" {
  type    = string
  default = null
}