#!/bin/bash

MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 2 ] && _fail "Usage: update-kernel.sh <vm name> <path to kernel>"

TMPFILE=$(mktemp)

if [[ ! -z "$USE_9P" ]]
then
	MOUNT_CMD="mount -t 9p -o ro,trans=virtio kernel /kernel"
	cat > $TMPFILE << EOF
<filesystem type='mount' accessmode='passthrough'>
	<source dir='$2' />
	<target dir='kernel' />
</filesystem>
EOF

else
	MOUNT_CMD="mount -t virtiofs -o ro kernel /kernel"
	cat > $TMPFILE << EOF
<filesystem type='mount' accessmode='passthrough'>
	<driver type='virtiofs' queue='1024' />
	<source dir='$2' />
	<target dir='kernel' />
</filesystem>
EOF

fi

virsh attach-device $1 --live $TMPFILE || _fail "Couldn't attach our device"

read -r -d '' COMMAND << EOM
$MOUNT_CMD
cd /kernel
make modules_install && make install && reboot
EOM

ssh root@$1 "$COMMAND"

virsh detach-device $1 --live $TMPFILE || _fail "Couldn't detach our device"
rm $TMPFILE

_wait_for_vm_to_boot $1
