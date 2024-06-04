# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "id" {
  value = azurerm_storage_account.storage_account.id
}

output "name" {
  value = azurerm_storage_account.storage_account.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.storage_account.primary_access_key
  sensitive = true
}