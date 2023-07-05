#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

IMAGE=$IMAGE_DIR/xfstests-btrfs.qcow2
VM_IMAGE=$IMAGE_DIR/$1.qcow2

[ ! -f "$IMAGE" ] && _fail "You must generate the base image first"

VIRTIOFS_XML="--xml ./devices/filesystem/driver/@type=virtiofs --xml ./devices/filesystem/driver/@queue=1024"
if [[ ! -z "$USE_9P" ]]
then
	VIRTIOFS_XML=""
fi

cp $IMAGE $VM_IMAGE
qemu-img resize $VM_IMAGE 10G

virt-install --memory 4096 --vcpus 2 --name $1 \
	--import --disk $VM_IMAGE,format=qcow2,bus=virtio \
	--os-variant fedora38 \
	--network bridge=virbr0,model=virtio \
	--graphics none \
	--noautoconsole \
	--boot uefi \
	--xml ./os/firmware/feature/@enabled=no \
	--xml ./os/firmware/feature/@name=secure-boot \
	--xml ./memoryBacking/source/@type=memfd \
	--xml ./memoryBacking/access/@mode=shared \
	--xml ./devices/filesystem/@type=mount \
	--xml ./devices/filesystem/@accessmode=passthrough \
	$VIRTIOFS_XML \
	--xml ./devices/filesystem/source/@dir=$KERNEL_DIR \
	--xml ./devices/filesystem/target/@dir=kernel || \
	_fail "Failed to create the guest, if it complained about virtiofs set USE_9P in local.config"

echo "Waiting for the network to become available"

while [ 1 ]
do
	sleep 5
	virsh domifaddr --source arp $1 | grep -q vnet && break
	virsh domifaddr --source arp $1 | grep -q tap && break
done

if virsh domifaddr --source arp $1 | grep -q vnet
then
	IP=$(virsh domifaddr --source arp $1 | grep vnet | awk '{ print $4 }' | cut -d '/' -f -1)
else
	IP=$(virsh domifaddr --source arp $1 | grep tap | awk '{ print $4 }' | cut -d '/' -f -1)
fi


cat >> ~/.ssh/config << EOF
Host $1 $IP
	Hostname $IP
	IdentityFile ~/.ssh/xfstests
	StrictHostKeyChecking no
EOF

_wait_for_vm_to_boot $1

TMPFILE=$(mktemp)

echo "$1" > $TMPFILE
scp $TMPFILE root@$1:/etc/hostname || _fail "Failed to set hostname"
echo "UPDATEDEFAULT=yes" > $TMPFILE
scp $TMPFILE root@$1:/etc/sysconfig/kernel || _fail "Failed to make fedora not be shit"
rm $TMPFILE

ssh root@$1 mkdir /kernel || _fail "Failed to create /kernel dir"

./checkout-xfstests.sh $1 || _fail "Failed to checkout and build xfstests"
./checkout-btrfs-progs.sh $1 || _fail "Failed to checkout and install btrfs-progs"
./setup-storage.sh $1 || _fail "Couldn't setup storage"
