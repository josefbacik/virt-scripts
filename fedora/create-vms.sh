#!/bin/bash

. ./local.config
. ./common

_create_guest()
{
	./create-guest.sh $1 || _fail "Couldn't create vm $i"
}

if [ ! -f $IMAGE_DIR/xfstests-btrfs.qcow2 ]
then
	./generate-image.sh || _fail "Couldn't generate the image"
fi

for i in ${VMS[@]}
do
	_create_guest $i &
done

wait
