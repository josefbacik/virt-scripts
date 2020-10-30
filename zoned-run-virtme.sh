#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage: zoned-run-virtme.sh <name> <vgname>"
	exit 1
fi

_fail() {
	echo $1
	exit 1
}

NAME=$1
VGNAME=$2

if [ ! -e "/dev/$VGNAME/$NAME-0" ]
then
	lvcreate -L 10g -n $NAME-$i $VGNAME || _fail "Couldn't create lv"
fi

CONFIG=/root/chroots/$NAME/fstests/local.config
ZONE_SCRIPT=/root/chroots/$NAME/create-zoned.sh

btrfs sub delete /root/chroots/$NAME || _fail "Couldn't delete snap"
btrfs sub snap /root/chroots/main /root/chroots/$NAME || \
	_fail "Couldn't create snap"

cat >$ZONE_SCRIPT <<EOF
#/bin/bash

mkdir "/sys/kernel/config/nullb/nullb0"
mkdir "/sys/kernel/config/nullb/nullb1"
    
echo "12800" > /sys/kernel/config/nullb/nullb0/size
echo "12800" > /sys/kernel/config/nullb/nullb1/size
echo 1 > /sys/kernel/config/nullb/nullb0/zoned
echo 0 > /sys/kernel/config/nullb/nullb0/zone_nr_conv
echo 1 > /sys/kernel/config/nullb/nullb0/memory_backed
echo 1 > /sys/kernel/config/nullb/nullb0/power
echo 1 > /sys/kernel/config/nullb/nullb1/zoned
echo 0 > /sys/kernel/config/nullb/nullb1/zone_nr_conv
echo 1 > /sys/kernel/config/nullb/nullb1/memory_backed
echo 1 > /sys/kernel/config/nullb/nullb1/power
udevadm settle

mkfs.btrfs -f /dev/nullb0
EOF

chmod a+x $ZONE_SCRIPT
echo "[btrfs]" > $CONFIG || _fail "Couldn't create local.config"
echo "FSTYP=btrfs" >> $CONFIG
echo "TEST_DIR=/test" >> $CONFIG
echo "TEST_DEV=/dev/nullb0" >> $CONFIG
echo "SCRATCH_DEV=/dev/nullb1" >> $CONFIG
echo "SCRATCH_MNT=/scratch" >> $CONFIG
echo "LOGWRITES_DEV=/dev/sda" >> $CONFIG
echo "[btrfs_compress]" >> $CONFIG
echo "MOUNT_OPTIONS=\"-o compress\"" >> $CONFIG

#	--script-sh "cd /fstests && ./check -g auto"  --net user \
#	--net user \
#	--script-sh "/create-zoned.sh && cd /fstests && ./check btrfs/001" \

virtme-run --mods=auto --kdir /root/btrfs-devel --memory 30g \
	-a "null_blk.nr_devices=0" \
	--disk "d0=/dev/$VGNAME/$NAME-0" \
	--root /root/chroots/$NAME \
	--show-boot-console --rw --qemu-opts -smp 2 
