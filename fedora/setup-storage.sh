#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

echo "Shutting down guest to add devices"

virsh shutdown $1 || _fail "Couldn't shutdown vm"
while [ 1 ]
do
	virsh list | grep -q $1 || break
	sleep 5
done

if [[ -z "$VGNAME" ]]
then
	./create-image-disks.sh $1 || _fail "Couldn't create disk images"
else
	./create-lvs.sh $1 || _fail "Couldn't create lv's"
fi

virsh start $1 || _fail "Couldn't start $1"

echo "Waiting for the machine to come up"
while [ 1 ]
do
	ssh root@$1 uname -r > /dev/null 2>&1 && break
	sleep 5
done

FILE=$1-tmp.config

cat > $FILE << EOF
[btrfs]
TEST_DIR=/mnt/test
TEST_DEV=/dev/vdb
SCRATCH_DEV_POOL="/dev/vdc /dev/vdd /dev/vde /dev/vdg /dev/vdh /dev/vdi /dev/vdj"
SCRATCH_MNT=/mnt/scratch
LOGWRITES_DEV=/dev/vdk
MKFS_OPTIONS="-K"
EOF

scp $FILE root@$1:/root/fstests/local.config || _fail "Couldn't scp config"
ssh root@$1 "mkdir /mnt/test; mkdir /mnt/scratch" || _fail "Couldn't create dirs"
ssh root@$1 "mkfs.btrfs -f /dev/vdb" || _fail "Failed to mkfs the TEST_DEV"

rm $FILE
