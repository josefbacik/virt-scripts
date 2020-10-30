#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage: run-virtme.sh <name> <vgname>"
	exit 1
fi

_fail() {
	echo $1
	exit 1
}

NAME=$1
VGNAME=$2

for i in $(seq 0 9)
do
	[ -e "/dev/$VGNAME/$NAME-$i" ] && continue
	lvcreate -L 10g -n $NAME-$i $VGNAME || _fail "Couldn't create lvs"
done

CONFIG=/root/chroots/$NAME/fstests/local.config

btrfs sub delete /root/chroots/$NAME || _fail "Couldn't delete snap"
btrfs sub snap /root/chroots/main /root/chroots/$NAME || \
	_fail "Couldn't create snap"

_pool="/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi"

echo "[btrfs]" > $CONFIG || _fail "Couldn't create local.config"
echo "FSTYP=btrfs" >> $CONFIG
echo "TEST_DIR=/test" >> $CONFIG
echo "TEST_DEV=/dev/sda" >> $CONFIG
echo "SCRATCH_DEV_POOL=\"$_pool\"" >> $CONFIG
echo "SCRATCH_MNT=/scratch" >> $CONFIG
echo "LOGWRITES_DEV=/dev/sdj" >> $CONFIG
echo "[btrfs_compress]" >> $CONFIG
echo "MOUNT_OPTIONS=\"-o compress\"" >> $CONFIG

_disk_opts=
for i in $(seq 0 9)
do
	_disk_opts="--disk d$i=/dev/$VGNAME/$NAME-$i $_disk_opts"
done

echo $_disk_opts

#	--script-sh "cd /fstests && ./check -g auto"  --net user \
#	--net user \

virtme-run --mods=auto --kdir . --memory 2g $_disk_opts \
	--root /root/chroots/$NAME \
	--script-sh "mkfs.btrfs -f /dev/sda && cd /fstests && ./check -g auto" \
	--show-boot-console --rw --qemu-opts -smp 2 
