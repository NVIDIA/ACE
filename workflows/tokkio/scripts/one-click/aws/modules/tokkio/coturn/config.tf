# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "aws_s3_object" "install_aws_cli" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-aws-cli.sh", local.name)
  content = file("${path.module}/config/install-aws-cli.sh")
}

resource "aws_s3_object" "coturn_server_env" {
  bucket = var.base_config.config_bucket
  key    = format("%s/coturn-server-env.sh", local.name)
  content = templatefile("${path.module}/config/coturn-server-env.sh.tpl", {
    name   = local.name
    coturn = var.coturn_settings
  })
}

resource "aws_s3_object" "setup_coturn_server" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-coturn-server.sh", local.name)
  content = file("${path.module}/config/setup-coturn-server.sh")
}