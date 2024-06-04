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
  value = one([
    for access_config in flatten([
      for network_interface in google_compute_instance.this.network_interface : network_interface["access_config"]
    ]) : access_config["nat_ip"]
  ])
}
output "private_ip" {
  value = one([
    for network_interface in google_compute_instance.this.network_interface : network_interface["network_ip"]
  ])
}
output "self_link" {
  value = google_compute_instance.this.self_link
}
output "zone" {
  value = google_compute_instance.this.zone
}