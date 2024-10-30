#!/bin/bash
#########
# Script:   set-nfs-readahead.sh
# Date:     Dec 4th, 2023
# Author: 	kmac@qumulo.com
# Credit:   ted@qumulo.com
#
# Purpose:  Increase the NFS read ahead to 15360kb
#
# IMPORTANT! This MUST be run after the NFS export is mounted!
#
#########

echo ""

RABLOCKS=15360
for id in `sudo cat /proc/self/mountinfo | grep nfs  | awk '{print $3}'`
do
  CURRENT=`sudo cat /sys/class/bdi/${id}/read_ahead_kb`
  echo "Changing read ahead for NFS device $id from $CURRENT kb --> $RABLOCKS"
  sudo bash -c "echo $RABLOCKS > /sys/class/bdi/${id}/read_ahead_kb"
  echo ""
done

echo "Validating that the change worked, should see $RABLOCKS in this output:"
for id in `sudo cat /proc/self/mountinfo | grep nfs  | awk '{print $3}'`
do
  CURRENT=`sudo cat /sys/class/bdi/${id}/read_ahead_kb`
  echo "New read ahead value for ${id} is set to: $RABLOCKS"
done

