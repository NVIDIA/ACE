# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

module "rp_vm" {
  source                                = "../../azure/linux-virtual-machine"
  name                                  = format("%s-rp", local.name)
  resource_group_name                   = var.base_config.resource_group.name
  region                                = var.base_config.networking.region
  subnet_id                             = var.base_config.networking.rp_vm_subnet_id
  include_public_ip                     = true
  size                                  = local.vm_details.size
  zone                                  = local.vm_details.zone
  user_data_with_public_ip_placeholder  = local.config_user_data_with_public_ip_placeholder
  user_data_public_ip_placeholder_regex = local.instance_public_ip_placeholder_regex
  admin_username                        = local.vm_details.admin_username
  ssh_public_key                        = var.base_config.keypair.public_key
  accelerated_networking                = local.vm_details.accelerated_networking
  image_details                         = local.vm_details.image_details
  os_disk_details                       = local.vm_details.os_disk_details
  data_disk_details                     = local.vm_details.data_disk_details
  identity                              = local.vm_details.identity
}