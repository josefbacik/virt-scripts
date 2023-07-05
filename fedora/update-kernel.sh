#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

MOUNT_CMD="mount -t virtiofs -o ro kernel /kernel"

if [[ ! -z "$USE_9P" ]]
then
	MOUNT_CMD="mount -t 9p -o ro,trans=virtio kernel /kernel"
fi

read -r -d '' COMMAND << EOM
$MOUNT_CMD
cd /kernel
make modules_install && make install && reboot
EOM

ssh root@$1 "$COMMAND"

_wait_for_vm_to_boot $1
