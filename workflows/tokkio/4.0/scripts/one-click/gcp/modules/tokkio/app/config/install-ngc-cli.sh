#!/bin/bash


echo "Install NGC CLI -- Start"

apt-get -y update
apt-get -y install unzip
wget --quiet --content-disposition https://ngc.nvidia.com/downloads/ngccli_linux.zip -O /tmp/ngccli_linux.zip
mkdir -p /usr/local/lib
unzip -q /tmp/ngccli_linux.zip -d /usr/local/lib
ln -s /usr/local/lib/ngc-cli/ngc /usr/local/bin/ngc

echo "Install NGC CLI -- End"