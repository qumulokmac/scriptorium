#!/bin/bash 

$DIR="/kdd"
while true
do
    date
    echo " "
    df -i /${DIR} | awk '{print $3 "     " $4}' | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
    echo " "
    echo "-----------------------------------------"
    sleep 300
done
