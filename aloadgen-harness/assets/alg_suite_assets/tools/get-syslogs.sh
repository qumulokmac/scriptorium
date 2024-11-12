

for i in `cat ~/nodes.conf`
do
	mkdir $i
	scp -rp -i ~/keys/grumpquat ubuntu@${i}:/run/qumulo/qcore_container/root/overlay/var/log/syslog* $i/
done	
