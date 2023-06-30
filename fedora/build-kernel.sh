#!/bin/bash

. ./local.config
. ./common

cd $KERNEL_DIR
git reset --hard
git checkout master || _fail "Failed to checkout master"
git branch -D for-next
git pull || _fail "Failed to pull"
git checkout for-next || _fail "Failed to checkout for-next"
make olddefconfig || _fail "olddefconfig failed"
make clean || _fail "make clean failed"
make -j32
