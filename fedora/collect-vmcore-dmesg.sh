#!/bin/bash

CURPATH=$(pwd)
MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "Usage: collect-vmcore-dmesg.sh <vm name>"

_wait_for_vm_to_boot $1

filename=$(ssh root@$1 'find /var/crash -name vmcore-dmesg.txt | grep .')
if [ "$?" -eq 1 ]
then
	echo "No crash file found, bailing"
	exit 0
fi

scp root@$1:$filename $CURPATH/$1-dmesg.txt
ssh root@$1 "rm -rf /var/crash/*"
