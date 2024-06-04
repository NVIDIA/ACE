# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

provider "aws" {
  region     = var.provider_config.region
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}

# fixed region for cloudfront certs
provider "aws" {
  region     = "us-east-1"
  alias      = "cloudfront"
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}