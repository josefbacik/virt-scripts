#!/bin/bash

_fail()
{
	echo $1
	exit 1
}

_get_last_addr()
{
	_addrs=$(virsh net-dumpxml default | grep host | tail -n 1)
	if [ -z "${_addrs}" ]
	then
		echo "100"
	else
		_last=$(echo ${_addrs} | python -c "import re; import sys; \
			sys.stdout.write(''.join(re.search('ip=\'\d+\.\d+\.\d+\.(\d+)\'', \
				sys.stdin.read()).group(1)));")
		_last=$((_last + 1))
		echo ${_last}
	fi
}

[ "$#" -ne 1 ] && _fail "xfstests-guest-install.sh <name>"

if [ ! -f ~/.ssh/xfstests.pub ]
then
	echo "Generating xfstests key"
	ssh-keygen -f ~/.ssh/xfstests -P ""
fi

dnf install -y qemu-system-aarch64

echo "Doing guest install"

virt-install --install fedora33 --disk size=10 --memory=4096 --vcpus=2 \
	--arch aarch64 --initrd-inject xfstests-ks-aarch64.cfg \
	--extra-args "ks=file:/xfstests-ks-aarch64.cfg" \
	--destroy-on-exit -n $1 || _fail "virt install failed"

echo "Installing ssh key for root"
mkdir -p mnt
guestmount -d $1 -i mnt || _fail "Couldn't mount, virt install failed"
mkdir mnt/root/.ssh
chmod 700 mnt/root/.ssh
cp ~/.ssh/xfstests.pub mnt/root/.ssh/authorized_keys
chmod 600 mnt/root/.ssh/authorized_keys
cp tarinstall.sh mnt/
cp setup-lvm-xfstests.sh mnt/
guestunmount mnt

# Wait a second, sometimes umount doesn't tear everything down faste enough
sleep 5

echo "Starting guest"
virsh start $1
./setup-storage.sh $1 || _fail "Couldn't setup storage"
virsh attach-disk --persistent $1 /dev/xfstests/$1 vdb || \
	_fail "Couldn't attach the disk"

echo "Setting up the networking"
_addr="192.168.122.$(_get_last_addr)"
_mac=$(virsh domifaddr ${1} | grep vnet | awk '{ print $2 }')
virsh net-update default add ip-dhcp-host \
	"<host mac='${_mac}' name='${1}' ip='${_addr}' />" \
	--live --config || _fail "Couldn't setup networking"

echo "${_addr} ${1}" >> /etc/hosts

cat >> ~/.ssh/config <<EOF
Host ${1}
	IdentityFile ~/.ssh/xfstests
EOF

echo "Rebooting then setting up storage, this takes a few seconds"
virsh reboot ${1}
sleep 30
ssh -o "StrictHostKeyChecking=accept-new" root@${1} \
	"/setup-lvm-xfstests.sh /xfstests-dev /dev/vdb" || \
	_fail "Couldn't setup the lvm xfstests devices"

echo "Box is ready to run xfstests"
