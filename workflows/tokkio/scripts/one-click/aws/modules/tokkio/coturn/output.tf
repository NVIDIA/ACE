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
  value = module.coturn_instance.public_ip
}
output "private_ip" {
  value = module.coturn_instance.private_ip
}
output "coturn_instance" {
  value = module.coturn_instance
}
output "port" {
  value = 3478
}
output "realm" {
  value = var.coturn_settings.realm
}
output "username" {
  value     = var.coturn_settings.username
  sensitive = true
}
output "password" {
  value     = var.coturn_settings.password
  sensitive = true
}