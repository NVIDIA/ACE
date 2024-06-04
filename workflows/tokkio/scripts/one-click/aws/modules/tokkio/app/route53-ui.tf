# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "aws_route53_record" "cloudfront_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.ui_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ui_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.ui_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
