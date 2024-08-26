#!/bin/bash


echo "Setup TOKKIO UI -- Start"

_resource_name="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $1}' | awk -F '/' '{print $3}')"
_org_name="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $1}' | awk -F '/' '{print $1}')"
_resource_version="$( echo -n "${TOKKIO_UI_RESOURCE_URL}" | awk -F ':' '{print $2}')"
_tar_artifact_dir="${_resource_name}_v${_resource_version}"
_tar_artifact_name="${_tar_artifact_dir}/${TOKKIO_UI_FILE}"
rm -rf tokkio-ui
rm -rf "${_tar_artifact_dir}"
mkdir -p tokkio-ui
ngc user who --org "${_org_name}"
ngc registry resource download-version "${TOKKIO_UI_RESOURCE_URL}" --org "${_org_name}"
tar -C tokkio-ui -xf "${_tar_artifact_name}"
cd tokkio-ui
bash ./init.sh
gsutil rsync -r ./build "gs://${WEB_ASSETS_BUCKET_ID}"

echo "Setup TOKKIO UI -- End"