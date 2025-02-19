#!/bin/bash


echo "Setup FOUNDATIONAL CHARTS -- Start"

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --cleanup-on-fail \
  --atomic \
  --reset-values \
  --wait \
  --create-namespace \
  --namespace "${FOUNDATIONAL_NS}" \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  mdx-local-path-provisioner \
  https://helm.ngc.nvidia.com/nvidia/ucs-ms/charts/mdx-local-path-provisioner-0.3.0.tgz

echo "Setup FOUNDATIONAL CHARTS -- End"