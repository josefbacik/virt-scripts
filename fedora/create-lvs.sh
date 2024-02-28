#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

DEVICES=("vdb" "vdc" "vdd" "vde" "vdf" "vdg" "vdh" "vdi" "vdj" "vdk" "vdl")

for i in $(seq 0 10)
do
	lvcreate --yes -W y -n $1-lv$i -L 12g $VGNAME || _fail "couldn't create lv $1-$lvi"
	virsh attach-disk --persistent $1 /dev/$VGNAME/$1-lv$i ${DEVICES[$i]} \
		|| _fail "couldn't attatch disk"
done
