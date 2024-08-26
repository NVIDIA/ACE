#!/bin/bash


echo "Installing gcloudcli -- Start"
export DEBIAN_FRONTEND=noninteractive
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt-get -y update && sudo apt-get -y install google-cloud-sdk

gcloud --version
status=$?

if [ $status -eq 0 ]; then
    echo "gcloud cli installation is successful."
else
    echo "gcloud cli installation is failed with exit status $status."
fi