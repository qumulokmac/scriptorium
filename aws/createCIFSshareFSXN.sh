#!/bin/bash 

export MGMTIP="YOUR_MGMT_IP_ADDRESS"
export ACCT="fsxadmin"
export PASSWD='YOURPASSWORD'
export SHARENAME='YOURSHARENAME'

###
# cifs show
###
sshpass -p "${PASSWD}" ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "cifs show"

###
# Create a Qtree
# create -qtree KMACS -volume svm101_root -security-style NTFS -oplock-mode enable  -vserver svm101
# 
###
sshpass -p "${PASSWD}" ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "qtree create -vserver svm101 -volume svm101_root -security-style NTFS -oplock-mode enable -qtree ${SHARENAME}"

###
# Create the share
###
sshpass -p "${PASSWD}" ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "cifs share create -share-name ${SHARENAME} -path /vol101/${SHARENAME} -share-properties oplocks,browsable,show-previous-versions -symlink-properties symlinks -offline-files manual -vscan-fileop-profile standard -max-connections-per-share 4294967295"

###
# Show the results
###
sshpass -p "${PASSWD}" ssh -o StrictHostKeyChecking=no ${ACCT}@${MGMTIP} "vserver cifs share show "
 # vserver cifs share show
