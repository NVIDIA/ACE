# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.
resource "google_service_account" "service_account" {
  account_id = local.name
}

resource "google_storage_bucket_iam_member" "config_viewer_access" {
  bucket = local.config_bucket_name
  role   = "roles/storage.objectViewer"
  member = format("serviceAccount:%s", google_service_account.service_account.email)
}