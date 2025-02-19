#!/bin/bash


echo "Verify GPU Operator Ready -- Start"

while [[ "$(kubectl --kubeconfig /etc/kubernetes/admin.conf --namespace nvidia-gpu-operator --no-headers --field-selector="status.phase!=Succeeded,status.phase!=Running" get pods | wc -l)" != 0 ]]; do
  sleep 10
  echo "Waiting for GPU Operator to get READY..."
done

echo "Verify GPU Operator Ready -- End"
