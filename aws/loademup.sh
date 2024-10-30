
COUNT=10000
for file in `cat /tmp/smaller-audio-files.txt `
do 
	COUNT=$(($COUNT+1))
	echo aws s3 cp $file s3://octankhealthpilot/inbound/OcTankHealthAudioDictation-${COUNT}.mp3
	aws s3 cp $file s3://octankhealthpilot/inbound/OcTankHealthAudioDictation-${COUNT}.mp3
	sleep 3
done
