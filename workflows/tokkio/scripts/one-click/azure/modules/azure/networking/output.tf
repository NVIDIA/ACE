# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "region" {
  value = azurerm_virtual_network.virtual_network.location
}

output "virtual_network_id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "subnet_ids" {
  value = { for subnet in var.subnet_details : subnet.identifier => azurerm_subnet.subnet[subnet.identifier].id }
}