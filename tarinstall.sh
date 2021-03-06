#!/bin/bash

_fail()
{
	echo $1
	exit 1
}

[ "$#" -ne 1 ] && _fail "tarinstall.sh <tarball>"

_version=$(echo $1 | python -c "import re; import sys; sys.stdout.write(''.join(re.search('linux-(.*)-x86\.tar', sys.stdin.read()).group(1)));")
tar xf $1 || _fail "Couldn't untar the kernel"
rm -f /boot/vmlinux-${_version} || _fail "Couldn't remove the vmlinux"
mkinitrd -f /boot/initramfs-${_version}.img ${_version} || \
	_fail "Couldn't make the initrd"
grubby --add-kernel /boot/vmlinuz-${_version} \
	--initrd /boot/initramfs-${_version}.img --make-default \
	--title ${_version} --copy-default
