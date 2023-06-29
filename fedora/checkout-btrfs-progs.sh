#!/bin/bash

_fail() {
	echo $1
	exit 1
}

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
git clone https://github.com/kdave/btrfs-progs.git
cd btrfs-progs
git reset --hard
git checkout master
git branch -D devel
git pull
git checkout devel
make clean-all
./autogen.sh
./configure --disable-documentation --enable-experimental --bindir=/usr/sbin --prefix=/usr --exec-prefix=/usr --disable-python
make -j4
make install
EOM

echo "$COMMAND"
ssh root@$1 "$COMMAND"
