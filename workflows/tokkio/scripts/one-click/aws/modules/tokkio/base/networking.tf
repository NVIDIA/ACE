# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

module "networking" {
  source               = "../../aws/networking"
  cidr_block           = var.cidr_block
  vpc_name             = format("%s-vpc", var.name)
  public_subnet_names  = [for i in range(1, 3) : format("%s-pub-%s", var.name, i)]
  private_subnet_names = [for i in range(1, 3) : format("%s-prv-%s", var.name, i)]
}