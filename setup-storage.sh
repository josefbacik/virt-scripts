#!/bin/bash

_fail() {
	echo $1
	exit 1
}

[ "$#" -ne 1 ] && _fail "must specify a disk or a name"

if [ -b "$1" ]
then
	[ -d "/dev/mapper/xfstests" ] && _fail "storage already initialized"
	vgcreate xfstests $1
	exit 0
fi

lvcreate -L 150g --name $1 xfstests
