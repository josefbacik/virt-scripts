#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: setup-chroot.sh <directory>"
	exit 1
fi
 
DIR=$(realpath $1)
RELEASEVER=32

btrfs subvolume create $DIR/chroots
btrfs subvolume create $DIR/chroots/main

dnf install -y busybox

dnf install -y --releasever=$RELEASEVER --installroot=$DIR/chroots/main
	systemd passwd dnf fedora-release lvm2 bc attr btrfs-progs fio hostname
	perl xfsprogs e2fsprogs openssh-server bash iproute busybox

ssh-keygen -f $DIR/chroots/main/etc/ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f $DIR/chroots/main/etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
ssh-keygen -f $DIR/chroots/main/etc/ssh/ssh_host_ed25519_key -N '' -t ed25519

mkdir $DIR/chroots/main/test
mkdir $DIR/chroots/main/scratch

cd $DIR/chroots/main
git clone https://github.com/btrfs/fstests.git
cd fstests
git checkout staging
make
