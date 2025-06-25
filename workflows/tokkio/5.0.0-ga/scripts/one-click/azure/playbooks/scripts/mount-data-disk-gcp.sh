#!/bin/bash


echo "Mount Data Disk -- Start"

apt-get update
apt-get install jq -y
DEVNAME="/dev/$(lsblk -bdnJI 8,259 -o NAME,SIZE,SERIAL | jq -r '.blockdevices | map(select(.serial == "data")) | map(.name) | .[0]')"
pvcreate "${DEVNAME}"
lvm_group_name=tokkio-volume-group

vgcreate ${lvm_group_name} "${DEVNAME}"

lvcreate -L 400G -n containerd ${lvm_group_name}
VDEVNAME="/dev/${lvm_group_name}/containerd"
mkfs -t ext4 ${VDEVNAME}
VDEVUUID=$(blkid ${VDEVNAME} -o export | grep '^UUID' | awk -F '=' '{print $2}')
mkdir -p /var/lib/containerd
echo "UUID=${VDEVUUID}  /var/lib/containerd  ext4  defaults,nofail  0  2" | tee -a /etc/fstab

lvcreate -l 100%FREE -n opt ${lvm_group_name}
VDEVNAME="/dev/${lvm_group_name}/opt"
mkfs -t ext4 ${VDEVNAME}
VDEVUUID=$(blkid ${VDEVNAME} -o export | grep '^UUID' | awk -F '=' '{print $2}')
mkdir -p /opt
echo "UUID=${VDEVUUID}  /opt  ext4  defaults,nofail  0  2" | tee -a /etc/fstab

mount -a

echo "Mount Data Disk -- End"