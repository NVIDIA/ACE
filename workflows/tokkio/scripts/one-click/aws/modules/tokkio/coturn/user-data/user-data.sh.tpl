#!/bin/bash


export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  apt-transport-https \
  awscli \
  ca-certificates \
  gnupg-agent \
  jq \
  libseccomp2 \
  autotools-dev \
  debhelper \
  software-properties-common

mkdir -p /tmp/${name}

%{ for config_script in config_scripts }
aws s3 cp "s3://${config_bucket}/${config_script.path}" "/tmp/${config_script.path}"
echo "Hash of ${config_script.path} is ${config_script.hash}"
${config_script.exec} "/tmp/${config_script.path}"
%{ endfor }