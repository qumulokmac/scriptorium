#!/bin/bash 

export MGMTIP="198.19.255.133"
export ACCT="fsxadmin"
export PASSWD='P@55w0rd123!' 
export SHARENAME='KMACS'

###
# cifs show
###
sshpass -p 'P@55w0rd123!' ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "cifs show"

###
# Create a Qtree
# create -qtree KMACS -volume svm101_root -security-style NTFS -oplock-mode enable  -vserver svm101
# 
###
sshpass -p 'P@55w0rd123!' ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "qtree create -vserver svm101 -volume svm101_root -security-style NTFS -oplock-mode enable -qtree ${SHARENAME}"

###
# Create the share
###
sshpass -p 'P@55w0rd123!' ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "cifs share create -share-name ${SHARENAME} -path /vol101/${SHARENAME} -share-properties oplocks,browsable,show-previous-versions -symlink-properties symlinks -offline-files manual -vscan-fileop-profile standard -max-connections-per-share 4294967295"

###
# Show the results
###
sshpass -p 'P@55w0rd123!' ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "vserver cifs share show "
 # vserver cifs share show
