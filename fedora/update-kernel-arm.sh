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

sudo virsh attach-device $1 --config $TMPFILE || _fail "Couldn't attach our device"
sudo virsh shutdown $1
while [ 1 ]
do
	sleep 10
	sudo virsh list | grep -q $1 || break
done

sudo virsh start $1
_wait_for_vm_to_boot $1

read -r -d '' COMMAND << EOM
./clean-kernels.sh
$MOUNT_CMD
cd /kernel
make modules_install && make install
EOM

if ! ssh root@$1 "$COMMAND"
then
	sudo virsh detach-device $1 --config $TMPFILE
	_fail "Couldn't install the kernel"
fi

ssh root@$1 "reboot"

sudo virsh detach-device $1 --config --live $TMPFILE || _fail "Couldn't detach our device"
rm $TMPFILE

_wait_for_vm_to_boot $1
