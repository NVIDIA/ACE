# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "aws_lb_listener" "this" {
  load_balancer_arn = var.lb_arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  dynamic "default_action" {
    for_each = var.default_action == "fixed-response" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = var.fixed_response_action_configs.content_type
        status_code  = var.fixed_response_action_configs.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = var.default_action == "redirect" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = var.redirect_action_configs.port
        protocol    = var.redirect_action_configs.protocol
        status_code = var.redirect_action_configs.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = var.default_action == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = var.forward_action_configs.target_group_arn
    }
  }
}