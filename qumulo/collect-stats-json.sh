#!/bin/bash 


bytes_to_human()
{
########################
# FIO reports bytes as kb
########################
  B=$(($1*1024))
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && return
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && return
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && return
  echo "GBGBGB is $GB"
  TB=$(((GB+512)/1024))
  [ $TB -lt 1024 ] && echo ${TB} TB && return
}

declare -i TOTAL_READ_IOPS=0
declare -i TOTAL_WRITE_IOPS=0
declare -i TOTAL_WRITE_BW=0
declare -i TOTAL_READ_BW=0
declare -i TOTAL_IOPS=0
declare -i TOTAL_BW=0
declare -i jobs=0

for file in `find json -name "*.json" -type f `
do
  jobs=$(($jobs+1))
  # echo "Reading Log $file:" 
  RIOPS=`jq -r '.jobs[0].read.iops_max' $file`
  #printf "\t\t\t\tREAD IOPS\t$RIOPS\n"

  WIOPS=`jq -r '.jobs[0].write.iops_max' $file`
  #printf "\t\t\t\tWRITE IOPS\t$WIOPS\n" 

  READ_BW=`jq -r '.jobs[0].read.bw' $file`
  #printf "\t\t\t\tREAD BW\t$READ_BW\n" 
  
  WRITE_BW=`jq -r '.jobs[0].write.bw' $file`
  #printf "\t\t\t\tWRITE BW\t$WRITE_BW\n" 
  
  LATENCYMS=`jq -r '.jobs[0].latency_ms' $file`

  TOTAL_READ_IOPS=$((TOTAL_READ_IOPS+RIOPS))
  TOTAL_WRITE_IOPS=$((TOTAL_WRITE_IOPS+WIOPS))
  TOTAL_READ_BW=$((TOTAL_READ_BW+READ_BW))
  TOTAL_WRITE_BW=$((TOTAL_WRITE_BW+WRITE_BW))
  TOTAL_IOPS=$((TOTAL_READ_IOPS+TOTAL_WRITE_IOPS))
  TOTAL_BW=$((TOTAL_BW+READ_BW+WRITE_BW))
  TIME_ELAPSED=`jq -r '.jobs[0].elapsed' $file`

done

# echo "Latency Distribution\t: $LATENCYMS (ms)"
printf "\nJob Runtime:\t\t\t$TIME_ELAPSED (seconds)\n"
printf "Number of jobs: \t\t$jobs jobs\n"
printf "Aggregate IOPS:\t\t\t$TOTAL_IOPS IOPS\n"

HUMAN_BW=`echo "scale=2;$TOTAL_BW/1024/1024" |bc`

printf "Aggregate Bandwidth:\t\t$HUMAN_BW GB/s\n"





