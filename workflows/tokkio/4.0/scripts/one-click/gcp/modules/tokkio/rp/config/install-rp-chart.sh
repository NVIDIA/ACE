#!/bin/bash


echo "Setup RP Chart -- Start"

echo 'rProxySpec:
  nodeSelector:
    type: rp
  tolerations:
  - key: "rproxy-node"
    operator: "Exists"
  publicInterfaceName: "ens4"
  privateInterfaceName: "ens4"
  imagePullSecrets:
  - name: ngc-docker-reg-secret
  checkIPUri: "http://checkip.amazonaws.com"' > /tmp/rproxy-override-values.yml 

helm upgrade \
  --kubeconfig /etc/kubernetes/admin.conf \
  --install \
  --cleanup-on-fail \
  --reset-values \
  --create-namespace \
  --namespace default \
  --username '$oauthtoken' \
  --password "${NGC_CLI_API_KEY}" \
  --values /tmp/rproxy-override-values.yml \
  rp-app \
  "${RP_CHART_URL}"

echo "Setup RP Chart -- End"