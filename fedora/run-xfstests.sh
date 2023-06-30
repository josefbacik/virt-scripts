#!/bin/bash

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
cd fstests
./check -g auto
EOM

ssh root@$1 "$COMMAND"
