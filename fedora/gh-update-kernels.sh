#!/bin/bash

VMS=("xfstests5" "xfstests6" "xfstests7" "xfstests8" "xfstests9" "xfstests10")

_update_vm()
{
	_vm=$1
	_kernel=$2
	_piddir=$3
	
	./update-kernel.sh $_vm $_kernel
	echo $? > $_piddir/$BASHPID
}

cd ~/virt-scripts/fedora

TMPDIR=$(mktemp -d)

for i in ${VMS[@]}
do
	_update_vm $i $1 $TMPDIR &
done

wait

_ret=0

for file in "$TMPDIR"/*
do
	_ret=$(<$file)
	[ "$_ret" -ne "0" ] && echo "One of the children failed" && break
done

rm -rf $TMPDIR
[ "$_ret" -ne "0" ] && exit 1

exit 0
