# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

variable "cdn_endpoint_id" {
  type = string
}

variable "cdn_endpoint_fqdn" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "ui_sub_domain" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}