#!/bin/bash

_fail() {
	echo $1
	exit 1
}

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
mount -t virtiofs -o ro kernel /kernel
cd /kernel
make modules_install && make install && reboot
EOM

ssh root@$1 "$COMMAND"

echo "Waiting for the box to come back up"
while [ 1 ]
do
	sleep 5
	ssh root@$1 uname -r 2> /dev/null && break
done
