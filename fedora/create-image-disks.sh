#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

DEVICES=("vdb" "vdc" "vdd" "vde" "vdf" "vdg" "vdh" "vdi" "vdj" "vdk")

for i in $(seq 0 9)
do
	FILE=$IMAGE_DIR/$1-${DEVICES[$i]}.qcow2

	qemu-img create -f qcow2 $FILE 10G || _fail "Couldn't create image file"
	
	virsh attach-disk --subdriver qcow2 --persistent $1 $FILE \
		${DEVICES[$i]} || _fail "couldn't attach disk"
done
