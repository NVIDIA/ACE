# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "google_storage_bucket_object" "coturn_server_env" {
  bucket = local.config_bucket_name
  name   = format("%s/coturn-server-env.sh", local.name)
  content = templatefile("${path.module}/config/coturn-server-env.sh.tpl", {
    coturn = var.coturn_settings
  })
}

resource "google_storage_bucket_object" "setup_coturn_server" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-coturn-server.sh", local.name)
  content = file("${path.module}/config/setup-coturn-server.sh")
}

locals {
  config_scripts = [
    {
      exec = "source"
      path = google_storage_bucket_object.coturn_server_env.name
      hash = google_storage_bucket_object.coturn_server_env.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_coturn_server.name
      hash = google_storage_bucket_object.setup_coturn_server.md5hash
    }
  ]
}