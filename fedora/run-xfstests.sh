#!/bin/bash

MYPATH=$(realpath $0)
cd $(dirname $MYPATH)

. ./local.config
. ./common

[ "$#" -ne 1 ] && _fail "must specify a vm name"

read -r -d '' COMMAND << EOM
cd fstests
./check -R xunit -g auto
EOM

ssh root@$1 "$COMMAND"

FIND_CMD="ssh root@$1 find /root/fstests -type f -name result.xml"

$FIND_CMD > /dev/null 2>&1 || _fail "Couldn't find results file"

FILE=$($FIND_CMD)

scp root@$1:$FILE /tmp/$1.xml
