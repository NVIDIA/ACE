# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

module "star_alb_certificate" {
  source           = "../../aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
}

module "star_cloudfront_certificate" {
  source           = "../../aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
  providers = {
    aws = aws.cloudfront
  }
}