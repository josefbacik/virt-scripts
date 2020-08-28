#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Creating 10gib image in the default location"
	IMAGE="size=10"
else
	IMAGE=$1
fi

if [ ! -f ~/.ssh/xfstests.pub ]
then
	echo "Generating xfstests key"
	ssh-keygen -f ~/.ssh/xfstests -P ""
fi

echo "Doing guest install"

virt-install --install fedora-rawhide --disk $IMAGE --memory=4096 --vcpus=2 \
	--initrd-inject xfstests-ks.cfg --extra-args "ks=file:/xfstests-ks.cfg" \
	--destroy-on-exit

echo "Installing ssh key for root"
mkdir -p mnt
guestmount -d fedora-rawhide -i mnt
mkdir mnt/root/.ssh
chmod 700 mnt/root/.ssh
cp ~/.ssh/xfstests.pub mnt/root/.ssh/authorized_keys
chmod 600 mnt/root/.ssh/authorized_keys
umount mnt

echo "Starting guest"
virsh start fedora-rawhide
