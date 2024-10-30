#!/bin/bash
#########################################
# On bastion/terminator host
#########################################
FSID=7b5aa3d8-5bdd-4eac-a9c6-a27297c094e9
for i in `echo {01..32}`
do
	echo "Copying syslog from node $i"
	qaas -e staging ssh --cluster-uuid $FSID -p 220${i} copy-file-from /var/log/syslog syslog-node${i}
done

#########################################
# On workstation
#########################################

scp kmcdonald@qaas-asa-terminator-staging:/home/kmcdonald/*.tgz .

