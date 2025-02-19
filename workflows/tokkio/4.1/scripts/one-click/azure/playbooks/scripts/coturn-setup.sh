#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.
if [ $1 == 'install' ]; then
  echo "Setup coturn server -- Start"
  DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y coturn

  if [ -n "$TURNSERVER_PUBLIC_IP" ] && [ -n "${TURNSERVER_PRIVATE_IP}" ]; then
    EXTERNAL_IP="${TURNSERVER_PUBLIC_IP}/${TURNSERVER_PRIVATE_IP}"
  elif [ -z "$TURNSERVER_PUBLIC_IP" ] && [ -n "${TURNSERVER_PRIVATE_IP}" ]; then
    EXTERNAL_IP="${TURNSERVER_PRIVATE_IP}"
  else
    echo "TURNSERVER_PRIVATE_IP variable ${TURNSERVER_PRIVATE_IP} is not set"
  fi

  sed \
    -e "s|^#TURNSERVER_ENABLED=1|TURNSERVER_ENABLED=1|g" \
    -i /etc/default/coturn

  sed \
    -e "/^#\?listening-device=/d" \
    -e "/^#\?listening-port=/d" \
    -e "/^#\?listening-ip=/d" \
    -e "/^#\?external-ip=/d" \
    -e "/^#\?relay-ip=/d" \
    -e "/^#\?min-port=/d" \
    -e "/^#\?max-port=/d" \
    -e "/^#\?fingerprint/d" \
    -e "/^#\?realm=/d" \
    -e "/^#\?user=/d" \
    -e "/^#\?log-file=/d" /etc/turnserver.conf \
    -i /etc/turnserver.conf

  cat <<EOF >> /etc/turnserver.conf
listening-device=${LISTENING_DEVICE}
listening-port=3478
listening-ip=${TURNSERVER_PRIVATE_IP}
external-ip=${EXTERNAL_IP}
relay-ip=${TURNSERVER_PRIVATE_IP}
min-port=49152
max-port=65535
fingerprint
realm=${TURNSERVER_REALM}
user=${TURNSERVER_USERNAME}:${TURNSERVER_PASSWORD}
log-file=/var/tmp/turn.log
EOF

  systemctl restart coturn

  echo "Setup coturn server -- End"

else
  systemctl stop coturn
  DEBIAN_FRONTEND=noninteractive
  apt-get purge coturn -y
  rm -rf /etc/turnserver.conf
fi