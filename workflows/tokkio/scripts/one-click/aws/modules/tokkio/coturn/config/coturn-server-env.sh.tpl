#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

export TURNSERVER_PRIVATE_IP="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
export TURNSERVER_PUBLIC_IP="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export TURNSERVER_REALM="${coturn.realm}"
export TURNSERVER_USERNAME="${coturn.username}"
export TURNSERVER_PASSWORD="${coturn.password}"