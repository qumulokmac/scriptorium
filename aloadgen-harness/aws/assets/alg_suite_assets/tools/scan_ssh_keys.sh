#!/usr/bin/bash 

for host in `cat ~/nodes.conf`; do
	ssh-keyscan $host >> ~/.ssh/known_hosts
done

