# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "public_ip" {
  value = one(azurerm_public_ip.public_ip.*.ip_address)
}

output "private_ip" {
  value = azurerm_network_interface.network_interface.private_ip_address
}

output "network_interface_id" {
  value = azurerm_network_interface.network_interface.id
}

output "ip_configuration_name" {
  value = azurerm_network_interface.network_interface.ip_configuration[0].name
}