#!/usr/bin/bash 

for host in `cat ~/conf/workers.conf`; do
	ssh-keyscan $host >> ~/.ssh/known_hosts
done

