#!/bin/bash 

###
# upload a fila using SHA256 as thei checksum algorithm 
###

aws s3api put-object --profile source --bucket kmacs-cloudshell-scripts --key testfile.txt --body testfile.txt --checksum-algorithm SHA256

###
# get an object and use SHA256 for checksum
###

aws s3api get-object --profile source --bucket kmacs-cloudshell-scripts --key testfile.txt --checksum-mode enabled /tmp/outfile


