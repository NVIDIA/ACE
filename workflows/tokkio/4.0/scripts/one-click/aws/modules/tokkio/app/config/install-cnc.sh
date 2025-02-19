#!/bin/bash


echo "CNS Install -- Start"
echo "Commit - ${CNS_COMMIT} "
echo "CNS Version - ${CNS_VERSION} "
sudo -H -u ubuntu bash -c 'ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""; cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'

git clone https://github.com/NVIDIA/cloud-native-stack.git /home/ubuntu/cloud-native-stack
git --git-dir=/home/ubuntu/cloud-native-stack/.git --work-tree=/home/ubuntu/cloud-native-stack checkout ${CNS_COMMIT}

sed -e "s|^#localhost.*|$(hostname -I | awk '{print $1}') ansible_ssh_common_args='-o StrictHostKeyChecking=no'|g" -i /home/ubuntu/cloud-native-stack/playbooks/hosts
echo -n "cns_version: ${CNS_VERSION}" > /home/ubuntu/cloud-native-stack/playbooks/cns_version.yaml

#condition to install gpu driver using runfile method
if [ "${GPU_DRIVER_RUNFILE_INSTALL}" = "true" ]; then
    echo "enabling cns_nvidia_driver flag to install gpu driver using runfile method"
    sed -i 's/cns_nvidia_driver: no/cns_nvidia_driver: yes/g' /home/ubuntu/cloud-native-stack/playbooks/cns_values_${CNS_VERSION}.yaml
fi

#condition to overwrite the gpu_driver_version
if [ "${GPU_DRIVER_VERSION}" != "default" ]; then
    echo "Using GPU_DRIVER_VERSION - ${GPU_DRIVER_VERSION}"
    sed -i "/gpu_driver_version/c\gpu_driver_version: \"$GPU_DRIVER_VERSION\"" /home/ubuntu/cloud-native-stack/playbooks/cns_values_${CNS_VERSION}.yaml
fi

chown -R ubuntu:ubuntu /home/ubuntu/cloud-native-stack

sudo -H -u ubuntu bash -c 'cd /home/ubuntu/cloud-native-stack/playbooks; bash setup.sh install'

echo "CNS Install -- End"