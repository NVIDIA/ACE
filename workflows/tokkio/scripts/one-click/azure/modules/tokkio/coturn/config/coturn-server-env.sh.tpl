#!/bin/bash


export TURNSERVER_PRIVATE_IP="$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r '.network.interface[0].ipv4.ipAddress[0].privateIpAddress')"
export TURNSERVER_PUBLIC_IP="$${INSTANCE_PUBLIC_IP}"
export TURNSERVER_REALM="${turnserver_realm}"
export TURNSERVER_USERNAME="${turnserver_username}"
export TURNSERVER_PASSWORD="${turnserver_password}"