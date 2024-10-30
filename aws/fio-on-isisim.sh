#!/bin/bash

MOUNTDIR=/private/nfs/fiodata

fio --name=fiotest --filename=${MOUNTDIR}/file --size=4Gb --rw=readwrite --bs=4K \
    --direct=1 --numjobs=8  --iodepth=32 --group_reporting \
    --runtime=60 --startdelay=60

exit
###################################
# Below is the jobfile.fio
###################################

[global]
name=fiotest
ioengine=libaio
direct=1
iodepth=32
group_reporting
runtime=60
startdelay=60

[random-rw-test1]
rw=read
bs=4k
size=1Gb
numjobs=8
filename=/private/nfs/fiodata
