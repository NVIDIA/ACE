# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

data "azurerm_storage_account" "mlops_storage_account" {
  count               = local.api_settings.mlops == null ? 0 : 1
  name                = local.api_settings.mlops.storage_account
  resource_group_name = local.api_settings.mlops.resource_group
}

data "azurerm_storage_container" "mlops_storage_container" {
  count                = local.api_settings.mlops == null ? 0 : 1
  name                 = local.api_settings.mlops.storage_container
  storage_account_name = data.azurerm_storage_account.mlops_storage_account[count.index].name
}