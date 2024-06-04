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
  value = var.include_public_ip ? aws_eip.this[0].public_ip : local.public_ip
}

output "private_ip" {
  value = aws_network_interface.this.private_ip
}

output "security_group_id" {
  value = one(aws_security_group.this.*.id)
}

output "security_group_ids" {
  value = aws_network_interface.this.security_groups
}

output "instance_id" {
  value = local.instance_id
}