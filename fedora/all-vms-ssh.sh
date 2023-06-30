#!/bin/bash

. ./local.config
. ./common

for i in ${VMS[@]}
do
	ssh root@$i $* &
done

wait
