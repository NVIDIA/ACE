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
  value = azurerm_key_vault.key_vault.id
}

output "name" {
  value = azurerm_key_vault.key_vault.name
}

output "access_policy" {
  value = { for access_policy in var.access_policies : azurerm_key_vault_access_policy.access_policy[access_policy.identifier].id => access_policy.object_id }
}