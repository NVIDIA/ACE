#!/bin/bash

export UI_STORAGE_ACCOUNT_NAME="${UI_STORAGE_ACCOUNT_NAME}"
export UI_STORAGE_ACCESS_CLIENT_ID="${UI_STORAGE_ACCESS_CLIENT_ID}"
export _resource_name="${resource_name}"
export _resource_team="${resource_team}"
export _org_name="${resource_org}"
export _resource_version="${resource_version}"
export TOKKIO_UI_RESOURCE_URL="$_org_name/$_resource_team/$_resource_name:$_resource_version"
export _resource_file="${resource_file}"

function install_azcopy() {
  if ! hash azcopy 2>/dev/null; then
    {
      wget \
        --quiet \
        --content-disposition \
        -O azcopy_v10.tar.gz \
        https://aka.ms/downloadazcopy-v10-linux
      tar -xf azcopy_v10.tar.gz --strip-components=1
      rm azcopy_v10.tar.gz
      rm NOTICE.txt
      mv azcopy /usr/local/bin/azcopy
    } > /dev/null
  fi
}

function install_ngc() {
  if ! hash ngc 2>/dev/null; then
    {
      if ! hash unzip 2>/dev/null; then
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
    _resource_name="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $1}' | awk -F '/' '{print $3}')"
    _org_name="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $1}' | awk -F '/' '{print $1}')"
    _resource_version="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $2}')"
    _tar_artifact_dir="${_resource_name}_v${_resource_version}"
    _tar_artifact_name="${_tar_artifact_dir}/${_resource_file}"
    rm -rf tokkio-ui
    rm -rf tokkio-ui-prepared
    rm -rf "${_tar_artifact_dir}"
    mkdir -p tokkio-ui
    ngc user who --org "${_org_name}"
    ngc registry resource download-version "${TOKKIO_UI_RESOURCE_URL}" --org "${_org_name}"
    tar -C tokkio-ui -xf "${_tar_artifact_name}"
    cd tokkio-ui
    python3 init.py
    cp *.js build/
    cd ..
    mv tokkio-ui/build tokkio-ui-prepared
  } > /dev/null
}

function upload_ui_code() {
  {
    azcopy login --identity --identity-client-id "${UI_STORAGE_ACCESS_CLIENT_ID}"
    azcopy remove "https://${UI_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/\$web/*" --recursive=true
    azcopy cp \
      "tokkio-ui-prepared/*" \
      "https://${UI_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/\$web" \
      --recursive=true
    rm -rf tokkio-ui-prepared
  } > /dev/null
}

function remove_ui_code() {
  {
    azcopy login --identity --identity-client-id "${UI_STORAGE_ACCESS_CLIENT_ID}"
    azcopy remove "https://${UI_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/\$web/*" --recursive=true
  } > /dev/null
}

if [ $1 == 'install' ]; then 
echo "Install Tokkio UI -- Start"
install_azcopy
install_ngc
prepare_ui_code
upload_ui_code
echo "Install Tokkio UI -- End"
else 
remove_ui_code
fi
