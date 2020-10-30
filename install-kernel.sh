#!/bin/bash

_fail()
{
	echo $1
	exit 1
}

[ "$#" -ne 2 ] && _fail "install-kernel.sh <guest name> <tarball>"

scp ${2} root@${1}:/
ssh root@${1} "cd /; ./tarinstall.sh ${2} && reboot"
