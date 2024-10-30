#!/bin/bash

for file in `ls -1 *.txt`
do
	mv ${file} .${file}.back
	iconv -f utf-16 -t utf-8 .${file}.back > $file
done
