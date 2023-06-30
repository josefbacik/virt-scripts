#!/bin/bash

. ./local.config
. ./common

_update_host()
{
	./update-xfstests.sh $1 || _fail "Failed to update xfstests on $1"
	./update-btrfs-progs.sh $1 || _fail "Failed to update btrfs-progs on $1"
	./update-kernel.sh $1 || _fail "Failed to update kernel on $1"
}

./build-kernel.sh || _fail "failed to build kernel"

for i in ${VMS[@]}
do
	_update_host $i &
done

wait
