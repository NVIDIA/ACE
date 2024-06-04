# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

module "bastion_vm" {
  source                 = "../../azure/linux-virtual-machine"
  name                   = format("%s-bastion", var.name)
  resource_group_name    = module.resource_group.name
  region                 = var.region
  subnet_id              = module.networking.subnet_ids[local.bastion_vm_details.subnet_identifier]
  include_public_ip      = true
  size                   = local.bastion_vm_details.size
  zone                   = local.bastion_vm_details.zone
  admin_username         = local.bastion_vm_details.admin_username
  ssh_public_key         = module.keypair.public_key
  accelerated_networking = local.bastion_vm_details.accelerated_networking
  image_details          = local.bastion_vm_details.image_details
  os_disk_details        = local.bastion_vm_details.os_disk_details
  data_disk_details      = local.bastion_vm_details.data_disk_details
}