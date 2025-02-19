#!/bin/bash


export TURNSERVER_PRIVATE_IP="$(hostname -I)"
export TURNSERVER_PUBLIC_IP="$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"
export TURNSERVER_REALM="${coturn.realm}"
export TURNSERVER_USERNAME="${coturn.username}"
export TURNSERVER_PASSWORD="${coturn.password}"