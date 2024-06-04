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

variable "vpc_id" {
  type = string
}

variable "port" {
  type = number
}

variable "protocol" {
  type = string
}

variable "instance_ids" {
  type = list(string)
}

variable "health_checks" {
  type = list(object({
    healthy_threshold   = number
    unhealthy_threshold = number
    interval            = number
    matcher             = string
    path                = string
    port                = number
    protocol            = string
    timeout             = number
  }))
}

variable "stickiness" {
  type = list(object({
    cookie_duration = number
    type            = string
    cookie_name     = string
    enabled         = bool
  }))
  default = []
}

variable "deregistration_delay" {
  type    = number
  default = 60
}