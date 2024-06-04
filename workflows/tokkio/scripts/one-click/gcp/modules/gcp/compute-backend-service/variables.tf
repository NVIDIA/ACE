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
variable "port_name" {
  type = string
}
variable "locality_lb_policy" {
  type = string
}
variable "load_balancing_scheme" {
  type = string
}
variable "group" {
  type = string
}
variable "access_policy" {
  type = object({
    rules = list(object({
      action   = string
      preview  = bool
      priority = number
      matches = list(object({
        versioned_expr = string
        configs = list(object({
          src_ip_ranges = list(string)
        }))
      }))
    }))
  })
  default = null
}
variable "http_health_checks" {
  type = list(object({
    request_path = string
    port         = number
  }))
  default = []
}