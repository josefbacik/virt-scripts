#!/bin/bash

. ./local.config
. ./common

IMAGE=$IMAGE_DIR/xfstests-btrfs.qcow2

# Start the build
composer-cli blueprints push xfstest-btrfs.toml || _fail "blueprint push failed"
composer-cli compose start xfstest-btrfs qcow2 || _fail "compose failed"

# Wait for it to finish
while [ 1 ]
do
	composer-cli compose status | grep -q RUNNING || break
	sleep 10
done

composer-cli compose list | grep -q 'xfstest-btrfs' || _fail "The compose didn't get created?"

UUID=$(composer-cli compose list | grep 'xfstest-btrfs' | head -n1 | awk '{ print $1 }')

composer-cli compose image $UUID --filename $IMAGE || _fail "couldn't save the image"

KEYFILE=$(realpath ~/.ssh/xfstests.pub)

virt-customize --add $IMAGE --ssh-inject root:file:$KEYFILE ||
	_fail "couldn't inject our ssh key"
