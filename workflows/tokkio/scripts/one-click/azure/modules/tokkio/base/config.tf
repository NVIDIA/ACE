# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "azurerm_user_assigned_identity" "config_reader" {
  name                = format("%s-config-reader", var.name)
  resource_group_name = module.resource_group.name
  location            = var.region
}

module "config_storage_account" {
  source              = "../../azure/storage-account"
  name                = format("%s-cf", var.name)
  resource_group_name = module.resource_group.name
  region              = var.region
}

resource "azurerm_role_assignment" "config_reader_access" {
  scope                = module.config_storage_account.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.config_reader.principal_id
}