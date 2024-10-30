#!/bin/bash
#######################################################################
#
# Creates an evenly distributed directory structure: 
#      [ NUMTLD * NUMSLD * 100k ] 16k files with random content 
#
#######################################################################

BASEPATH="/fc5a09/ns1/ns1/"
NUMTLD=320
NUMSLD=16

if [[ ! -e $BASEPATH ]]   
then
		echo "$BASEPATH doesnt exist?!"
		exit 77
fi

cd $BASEPATH

echo "Writing to:"
echo ""
df -h $BASEPATH
echo ""
echo "Starting at `date`"

for tld in `seq 1 $NUMTLD`
do
	mkdir ${BASEPATH}/${tld}
        # echo "Starting TLD $tld at `date`"
	for sld in `seq 1 $NUMSLD`
	do
		mkdir ${BASEPATH}/${tld}/${sld}
		seq -w 1 100000 | parallel -j 16 dd if=/dev/urandom of=${BASEPATH}/${tld}/${sld}/smallfile-{}.rnd bs=8k count=1 2>/dev/null &
    		pids[${sld}]=$!
		# echo "Added PID $! to watch list at pids[${sld}]"
	done
	for pid in ${pids[*]}; do
    		wait $pid
	done
	echo "Done with TLD round $tld at `date`"
done