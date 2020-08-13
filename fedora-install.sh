#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: fedora-install.sh <path to image>"
	exit 1
fi

IMAGE=$1

virt-install --install fedora-rawhide --disk $IMAGE --memory=4096 --vcpus=2 \
	--initrd-inject minimal-ks.cfg --extra-args "ks=file:/minimal-ks.cfg"
