# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

output "network_name" {
  value = google_compute_network.this.name
}
output "subnetworks" {
  value = {
    for subnet in var.subnets : subnet.name => {
      name    = google_compute_subnetwork.this[subnet.name].name
      private = subnet.private
    }
  }
}