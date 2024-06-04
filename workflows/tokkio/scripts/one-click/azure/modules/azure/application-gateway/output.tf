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
  value = { for frontend_ip_configuration in var.frontend_ip_configurations : frontend_ip_configuration.public_ip_name => azurerm_public_ip.public_ip[frontend_ip_configuration.public_ip_name].ip_address }
}