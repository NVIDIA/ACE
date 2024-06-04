# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  resource_group_name = var.resource_group_name
  location            = "global"
  sku                 = "Standard_Microsoft"
  tags                = var.additional_tags
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = var.cdn_endpoint_name
  resource_group_name = var.resource_group_name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = azurerm_cdn_profile.cdn_profile.location
  origin_host_header  = var.target_host_name
  origin {
    name      = replace(var.target_host_name, ".", "-")
    host_name = var.target_host_name
  }
}