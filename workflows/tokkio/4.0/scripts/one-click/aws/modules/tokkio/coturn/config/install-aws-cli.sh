#!/bin/bash


if ! hash aws 2>/dev/null; then
    echo "Installing awscli -- Start"
    {
      rm -f /tmp/awscliv2.zip
      curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      rm -rf /tmp/aws
      if ! hash unzip 2>/dev/null; then
        sudo apt-get -y update
        sudo apt-get -y install unzip
      fi
      unzip /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install
    } > /dev/null
    echo "Installing awscli -- End"
fi