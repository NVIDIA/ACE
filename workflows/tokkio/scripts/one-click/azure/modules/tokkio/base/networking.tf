# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

module "networking" {
  source                        = "../../azure/networking"
  name                          = var.name
  resource_group_name           = module.resource_group.name
  region                        = var.region
  virtual_network_address_space = var.virtual_network_address_space
  subnet_details                = local.subnet_details
  network_security_groups       = local.network_security_groups
  network_security_rules        = local.network_security_rules
}