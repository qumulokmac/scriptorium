#!/bin/bash 

# ./re-encode-to-utf8.sh
grep -m 1 "total\:" *txt > all.totals
# grep -A12 "Total IO" *.txt | grep total > all.totals

ALL_OUTPUT=()
command_output=$( cat all.totals )

while IFS= read -r line
do
	NAME=`echo $line | cut -d ':' -f 1`
	THIS_TPUT=`echo $line | cut -d '|' -f 3 | tr -d '[:space:]' `
	THIS_IOPS=`echo $line | cut -d '|' -f 4 | tr -d '[:space:]' `
	THIS_LATENCY=`echo $line | cut -d '|' -f 5 | tr -d '[:space:]' `

	echo "\"${NAME}\",\"$THIS_TPUT\",\"$THIS_IOPS\",\"$THIS_LATENCY\""

done <<< "$command_output"
