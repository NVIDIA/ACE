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
  value = azurerm_key_vault_certificate.certificate.id
}

output "versionless_id" {
  value = azurerm_key_vault_certificate.certificate.versionless_id
}

output "secret_id" {
  value = azurerm_key_vault_certificate.certificate.secret_id
}

output "versionless_secret_id" {
  value = azurerm_key_vault_certificate.certificate.versionless_secret_id
}

output "name" {
  value = azurerm_key_vault_certificate.certificate.name
}