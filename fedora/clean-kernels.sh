#!/bin/bash

rm -rf /boot/*.old
NUM=$(find /boot -type f -name vmlinuz* -printf "%T@ %p\n" | grep -v rescue | \
	sort -n | wc -l)

[ "$NUM" -le 4 ] && exit 0

for i in $(find /boot -type f -name vmlinuz* -printf  "%T@ %p\n" | \
		grep -v rescue | sort -n | cut -d '-' -f 2- | head -n 3)
do
	echo "Removing $i"
	rm -f /boot/initramfs-$i*.img
	rm -f /boot/System.map-$i
	rm -f /boot/vmlinuz-$i
	rm -rf /usr/lib/modules/$i
done
