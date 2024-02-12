#!/bin/bash

MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "Usage: check-vm-health.sh <vm name>"

ssh -o ConnectTimeout=5 root@$1 'uname -r'
if [ "$?" -ne 0 ]
then
	sudo virsh reset $1
	_wait_for_vm_to_boot $1
	exit 0
fi

ssh root@$1 'dmesg | grep -E -q -e "kernel BUG at" \
             -e "WARNING:" \
             -e "\bBUG:" \
             -e "Oops:" \
             -e "possible recursive locking detected" \
             -e "Internal error" \
             -e "(INFO|ERR): suspicious RCU usage" \
             -e "INFO: possible circular locking dependency detected" \
             -e "general protection fault:" \
             -e "BUG .* remaining" \
             -e "UBSAN:" \
             -e "leaked"'
if [ "$?" -eq 0 ]
then
	sudo virsh reset $1
	_wait_for_vm_to_boot $1
fi

exit 0
