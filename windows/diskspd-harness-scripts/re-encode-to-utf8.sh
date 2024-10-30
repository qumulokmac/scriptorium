#!/bin/bash

for file in `ls -1 *.txt`
do
  ENCODING=`file -I $file | cut -d '=' -f2`
  if [[ "${ENCODING}" != "us-ascii" ]]
  then
      echo "Encoding is $ENCODING, converting to ASCII" 
      mv ${file} .${file}.back
      iconv -f utf-16 -t utf-8 .${file}.back > $file
  fi
done
