#!/bin/bash

MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

if [ "$1" != "xfstests10" ]
then
	read -r -d '' COMMAND << EOM
cd fstests
git reset --hard
git checkout master
git branch -D staging
git pull
git checkout staging
make
cp btrfs-ci.config local.config
EOM

else
	read -r -d '' COMMAND << EOM
cd fstests
git reset --hard
git checkout master
git branch -D staging
git pull
git checkout staging
make
EOM
fi


ssh root@$1 "$COMMAND"
