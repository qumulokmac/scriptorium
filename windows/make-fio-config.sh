#!/bin/bash 

declare -i JOBID=0 
declare -i NUMWORKERS=16
while [ $JOBID -ne $NUMWORKERS ]
do
  for DRVLTR in `jot -r -c 16 F U`
  do
	JOBID=$((JOBID+1))
	echo "[job$JOBID]"
	echo "directory=$DRVLTR\:fio"
	echo "numjobs=1"
	echo ""
  done
done

exit
  # for DRVLTR in F G H I J K L M N O P Q R S T U
