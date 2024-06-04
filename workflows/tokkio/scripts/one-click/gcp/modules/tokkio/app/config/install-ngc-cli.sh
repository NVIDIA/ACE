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

echo "Install NGC CLI -- Start"

apt-get -y update
apt-get -y install unzip
wget --quiet --content-disposition https://ngc.nvidia.com/downloads/ngccli_linux.zip -O /tmp/ngccli_linux.zip
mkdir -p /usr/local/lib
unzip -q /tmp/ngccli_linux.zip -d /usr/local/lib
ln -s /usr/local/lib/ngc-cli/ngc /usr/local/bin/ngc

echo "Install NGC CLI -- End"