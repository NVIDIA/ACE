#!/bin/bash


export TURNSERVER_PRIVATE_IP="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
export TURNSERVER_PUBLIC_IP="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export TURNSERVER_REALM="${coturn.realm}"
export TURNSERVER_USERNAME="${coturn.username}"
export TURNSERVER_PASSWORD="${coturn.password}"