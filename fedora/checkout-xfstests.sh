#!/bin/bash

_fail() {
	echo $1
	exit 1
}

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
git clone https://github.com/btrfs/fstests.git
cd fstests
git checkout staging
make
EOM

ssh root@$1 "$COMMAND" || _fail "couldn't clone fstests"
