#!/bin/bash 
clear

DIR=/Users/mcaws/Documents/AwesomeBuilder/AB3/audio
cd $DIR 
echo "Working in: `pwd`" 

for mp3code in `find . -type f -size -1M -name "*.mp3" | cut -d '.' -f2 | cut -d '-' -f2 |sort -n`
do 
    if [ "${mp3code}" == "." ] 
    then
        echo "You found the hidden dot!"
        next
    fi

    CMD="cp ${DIR}/OcTankHealthAudioDictation-${mp3code}.mp3 /tmp/OcTankHealthAudioDictation-44442222.mp3" 
    echo "Identifier is ${mp3code}, performing: $CMD"; 
    `${CMD}`
    echo ""
    # echo "Hit enter when ready for the next mp3 file" 
    # read answer
    echo "Auto mode... in 300 seconds"
    sleep 300
    echo "Uploading iteration $mp3code"
    aws s3 cp /tmp/OcTankHealthAudioDictation-44442222.mp3 s3://octankhealthpilot/inbound/    
done
