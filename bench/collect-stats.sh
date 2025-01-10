#!/bin/bash

declare -i TOTAL_READ_IOPS=0
declare -i TOTAL_WRITE_IOPS=0
declare -i TOTAL_WRITE_BW=0
declare -i TOTAL_READ_BW=0
declare -i TOTAL_IOPS=0
declare -i TOTAL_BW=0

for file in `find . -name "*.log" -type f `
do
  echo "Log $file:" 
  RIOPS=`grep IOPS $file | sort -n | grep read | cut -d '=' -f2 | cut -d ',' -f1  | paste -s -d + - | bc`
  printf "\t\t\t\tREAD IOPS\t$RIOPS\n" 

  WIOPS=`grep IOPS $file | sort -n | grep write | cut -d '=' -f2 | cut -d ',' -f1  | paste -s -d + - | bc`
  printf "\t\t\t\tWRITE IOPS\t$WIOPS\n" 

  RBW=`grep BW $file | sort -n | grep read | cut -d '=' -f3 | cut -d 'k' -f1  | paste -s -d + - | bc`
  printf "\t\t\t\tREAD BW\t\t$RBW\n" 

  WBW=`grep BW $file | sort -n | grep write | cut -d '=' -f3 | cut -d 'k' -f1  | paste -s -d + - | bc`
  printf "\t\t\t\tWRITE BW\t$WBW\n" 

  LATAVG=`grep  'clat (msec' $file | awk '{ print $5 }' | sed -e 's/,//g' | sed -e 's/avg=//g' `
  printf "\t\t\t\tAverage Latency\t$LATAVG\n" 

  TOTAL_READ_IOPS=$((TOTAL_READ_IOPS+RIOPS))
  TOTAL_WRITE_IOPS=$((TOTAL_WRITE_IOPS+WIOPS))
  TOTAL_READ_BW=$((TOTAL_READ_BW+RBW))
  TOTAL_WRITE_BW=$((TOTAL_WRITE_BW+WBW))
  TOTAL_IOPS=$((TOTAL_READ_IOPS+TOTAL_WRITE_IOPS))
  TOTAL_BW=$((TOTAL_READ_BW+TOTAL_WRITE_BW))
	
done

echo ""
printf "Log Collection Aggregate IOPS:\t\t\t$TOTAL_IOPS\n"
printf "Log Collection Aggregate Bandwidth:\t\t$TOTAL_BW\n"
