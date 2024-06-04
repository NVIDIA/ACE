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
variable "alternate_region" {
  type = string
}
variable "force_destroy" {
  type = bool
}
variable "website_main_page_suffix" {
  type = string
}
variable "website_not_found_page" {
  type = string
}