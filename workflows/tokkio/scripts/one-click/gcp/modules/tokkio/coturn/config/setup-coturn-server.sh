#!/bin/bash


echo "Setup coturn server -- Start"

apt-get install -y coturn

sed \
  -e "s|^#TURNSERVER_ENABLED=1|TURNSERVER_ENABLED=1|g" \
  -i /etc/default/coturn

sed \
  -e "s|^#listening-device=eth0$|listening-device=eth0|g" \
  -e "s|^#listening-port=3478$|listening-port=3478|g" \
  -e "s|^#listening-ip=172.17.19.101$|listening-ip=${TURNSERVER_PRIVATE_IP}|g" \
  -e "s|^#relay-ip=172.17.19.105$|relay-ip=${TURNSERVER_PRIVATE_IP}|g" \
  -e "s|^#external-ip=60.70.80.91/172.17.19.101$|external-ip=${TURNSERVER_PUBLIC_IP}/${TURNSERVER_PRIVATE_IP}|g" \
  -e "s|^#min-port=49152$|min-port=49152|g" \
  -e "s|^#max-port=65535$|max-port=65535|g" \
  -e "s|^#fingerprint$|fingerprint|g" \
  -e "s|^#realm=mycompany.org$|realm=${TURNSERVER_REALM}|g" \
  -e "s|^#user=username1:password1$|user=${TURNSERVER_USERNAME}:${TURNSERVER_PASSWORD}|g" \
  -e "s|^#log-file=/var/tmp/turn.log$|log-file=/var/tmp/turn.log|g" \
  -i /etc/turnserver.conf

systemctl restart coturn

echo "Setup coturn server -- End"