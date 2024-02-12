#!/bin/bash

MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
cd btrfs-progs
git reset --hard
git checkout master
git pull
make clean-all
./autogen.sh
./configure --disable-documentation --enable-experimental --bindir=/usr/sbin --prefix=/usr --exec-prefix=/usr --disable-python
make -j4
make install
cp btrfs-corrupt-block /usr/sbin
EOM

ssh root@$1 "$COMMAND"
