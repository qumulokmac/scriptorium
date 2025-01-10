#!/usr/bin/bash 

for host in `cat ~/workers.conf`; do
	ssh-keyscan $host >> ~/.ssh/known_hosts
done

