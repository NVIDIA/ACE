#!/bin/bash
cd "${ansible_user_dir}"
export _resource_name="${resource_name}"
export _resource_team="${resource_team}"
export _org_name="${resource_org}"
export _resource_version="${resource_version}"
export _resource_file="${resource_file}"
export _tar_artifact_dir="${_resource_name}"_v"${_resource_version}"
export _tar_artifact_name="$_tar_artifact_dir/$_resource_file"
export NGC_CLI_API_KEY="${NGC_CLI_API_KEY}"
export PATH=$PATH:/usr/local/bin/ngc-cli

function install_gsutil() {
  if ! hash gsutil 2>/dev/null; then
    {
      DEBIAN_FRONTEND=noninteractive
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
      apt update
      apt install google-cloud-cli -y
    } > /dev/null
  fi
}

function install_ngc() {
  if ! hash ngc 2>/dev/null; then
    {
      if ! hash unzip 2>/dev/null; then
        DEBIAN_FRONTEND=noninteractive
        apt-get -y update
        apt-get -y install unzip
      fi
      wget \
        --quiet \
        --content-disposition \
        -O /tmp/ngccli_linux.zip \
        https://ngc.nvidia.com/downloads/ngccli_linux.zip
      mkdir -p /usr/local/lib
      unzip -q /tmp/ngccli_linux.zip -d /usr/local/lib
      rm /tmp/ngccli_linux.zip
      ln -s /usr/local/lib/ngc-cli/ngc /usr/local/bin/ngc
    } > /dev/null
  fi
}

function prepare_ui_code() {
  {
    sudo rm -rf tokkio-ui
    sudo rm -rf "${_tar_artifact_dir}"
    sudo mkdir -p tokkio-ui
    ngc user who --org "${_org_name}"
    export TOKKIO_UI_RESOURCE_URL="$_org_name/$_resource_team/$_resource_name:$_resource_version"
    ngc registry resource download-version "${TOKKIO_UI_RESOURCE_URL}" --org "${_org_name}"
    sudo tar -C tokkio-ui -xf "${_tar_artifact_name}"
    cd tokkio-ui
    mkdir -p tokkio-ui
    ngc user who --org "${_org_name}"
    ngc registry resource download-version "${TOKKIO_UI_RESOURCE_URL}" --org "${_org_name}"
    tar -C tokkio-ui -xf "${_tar_artifact_name}"
    cd tokkio-ui
    python3 init.py
    cp *.js build/
    sudo gsutil rm -r -f "gs://${WEB_ASSETS_BUCKET_ID}/**"
    sudo gsutil rsync -r ./build "gs://${WEB_ASSETS_BUCKET_ID}"
  } > /dev/null
}

function remove_ui_code() {
  {
    sudo gsutil rm -r -f "gs://${WEB_ASSETS_BUCKET_ID}/**"
  } > /dev/null
}

if [ $1 == 'install' ]; then 
echo "Install Tokkio UI -- Start"
install_gsutil
install_ngc
prepare_ui_code
echo "Install Tokkio UI -- End"
else 
echo "Stopping Tokkio UI"
remove_ui_code
echo "Stopped Tokkio UI"
fi
