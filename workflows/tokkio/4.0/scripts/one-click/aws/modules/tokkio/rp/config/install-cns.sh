#!/bin/bash


echo "CNS Install -- Start"
echo "Commit - ${CNS_COMMIT} "
echo "CNS Version - ${CNS_VERSION} "
sudo -H -u ubuntu bash -c 'ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""; cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'

git clone https://github.com/NVIDIA/cloud-native-stack.git /home/ubuntu/cloud-native-stack
git --git-dir=/home/ubuntu/cloud-native-stack/.git --work-tree=/home/ubuntu/cloud-native-stack checkout ${CNS_COMMIT}

sed -e "s|^#localhost.*|$(hostname -I | awk '{print $1}') ansible_ssh_common_args='-o StrictHostKeyChecking=no'|g" -i /home/ubuntu/cloud-native-stack/playbooks/hosts
echo "Setting flag to skip GPU Operator!!!"
sed -i 's/enable_gpu_operator:\syes/enable_gpu_operator: no/g' /home/ubuntu/cloud-native-stack/playbooks/cns_values_${CNS_VERSION}.yaml
echo -n "cns_version: ${CNS_VERSION}" > /home/ubuntu/cloud-native-stack/playbooks/cns_version.yaml
chown -R ubuntu:ubuntu /home/ubuntu/cloud-native-stack

sudo -H -u ubuntu bash -c 'cd /home/ubuntu/cloud-native-stack/playbooks; bash setup.sh install'

kubectl  --kubeconfig /etc/kubernetes/admin.conf label nodes "$(kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o=jsonpath='{.items[0].metadata.name}')" type=rp
kubectl  --kubeconfig /etc/kubernetes/admin.conf taint nodes "$(kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o=jsonpath='{.items[0].metadata.name}')" rproxy-node:NoSchedule

echo "CNS Install -- End"