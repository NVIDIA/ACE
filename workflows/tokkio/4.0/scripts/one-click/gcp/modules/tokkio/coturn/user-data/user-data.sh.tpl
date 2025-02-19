#!/bin/bash


export DEBIAN_FRONTEND=noninteractive
if ! [[ -f /etc/startup_was_launched ]]; then
  apt-get update
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    jq \
    libseccomp2 \
    autotools-dev \
    debhelper \
    software-properties-common

  mkdir -p /tmp/${name}

  %{ for config_script in config_scripts }
  gsutil cp "gs://${config_bucket}/${config_script.path}" "/tmp/${config_script.path}"
  echo "Hash of ${config_script.path} is ${config_script.hash}"
  ${config_script.exec} "/tmp/${config_script.path}"
  %{ endfor }
  
  touch /etc/startup_was_launched
  echo "listing /etc/startup_was_launched"
  ls -lrt /etc/startup_was_launched
else
  echo "/etc/startup_was_launched is present, so this is not first boot"
fi