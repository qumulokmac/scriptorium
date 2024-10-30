#!/bin/bash 

for file in `ls -1 *.json`
do 
	# octankhealth-s3-lambda-transcribe-job-fffb747e-9e54-4ab4-a779-2e96ec2c5b13.json
        TID=`echo $file | sed -e 's/octankhealth-s3-lambda-transcribe-job-//' | sed -e 's/.json//'`
	TRANSCRIPT=`jq '.results.transcripts[].transcript' $file`
	if [[ -z ${TRANSCRIPT}  ]] 
	then
		echo "NO TRANSCRIPT"
	else
		echo "\"${TID}\",${TRANSCRIPT}"   
	fi
done
