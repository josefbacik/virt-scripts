#!/bin/bash

VMS=("xfstests5" "xfstests6" "xfstests7" "xfstests8" "xfstests9" "xfstests10")

for i in ${VMS[@]}
do
	$* $i &
done

wait
