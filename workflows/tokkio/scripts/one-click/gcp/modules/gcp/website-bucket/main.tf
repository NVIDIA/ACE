# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "google_storage_bucket" "this" {
  name                        = format("%s-web-assets", var.name)
  location                    = var.location
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  website {
    main_page_suffix = var.website_main_page_suffix
    not_found_page   = var.website_not_found_page
  }
  custom_placement_config {
    data_locations = [
      upper(var.region),
      upper(var.alternate_region)
    ]
  }
}