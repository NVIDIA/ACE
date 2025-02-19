#!/bin/bash


export DEBIAN_FRONTEND=noninteractive
export CONFIG_STORAGE_ACCOUNT=${config_storage_account}
export CONFIG_STORAGE_CONTAINER=${config_storage_container}
export CONFIG_ACCESS_CLIENT_ID=${config_access_client_id}

function install_common_tools() {
  echo "Installing common tools -- Start"
  {
    apt-get update
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      gnupg-agent \
      jq \
      libseccomp2 \
      autotools-dev \
      debhelper \
      software-properties-common \
      jq
  } > /dev/null
  echo "Installing common tools -- End"
}

function install_azcopy() {
  if ! hash azcopy 2>/dev/null; then
    echo "Installing azcopy -- Start"
    {
      wget \
        --quiet \
        --content-disposition \
        -O azcopy_v10.tar.gz \
        https://aka.ms/downloadazcopy-v10-linux && \
        tar -xf azcopy_v10.tar.gz --strip-components=1 && \
        rm azcopy_v10.tar.gz && \
        rm NOTICE.txt && \
        mv azcopy /usr/local/bin/azcopy
    } > /dev/null
    echo "Installing azcopy -- End"
  fi
}

function download_configs() {
  echo "Downloading configs -- Start"
  {
     rm -rf /tmp/$${CONFIG_STORAGE_CONTAINER}
     azcopy login --identity --identity-client-id $${CONFIG_ACCESS_CLIENT_ID}
     azcopy cp "https://$${CONFIG_STORAGE_ACCOUNT}.blob.core.windows.net/$${CONFIG_STORAGE_CONTAINER}/" "/tmp" --recursive=true
  } > /dev/null
  echo "Downloading configs -- End"
}

printenv
install_common_tools
install_azcopy
download_configs

%{ for config_script in config_scripts }
echo "Hash of ${config_script.name} is ${config_script.hash}"
${config_script.exec} "/tmp/$${CONFIG_STORAGE_CONTAINER}/${config_script.name}"
%{ endfor }