#!/bin/bash
################################################################################
#
# Author:  KMac mcaws@amazon.com
# Date:    Sept 13th, 2022
# Script:  startPreviewBuild.sh 
# Why:     because.
################################################################################
if [ ! -e contentspec.yaml ] 
then
    echo "You are not in a workshop base directory, there is no contentspec YAML file."
    exit -1
fi

if [ `ps -ef | grep -i preview_build | grep -v grep | wc -l` != 0 ] 
then
    echo "Looks like preview_build is already running:  `ps -ef | grep -i preview_build | grep -v grep` "
    echo ""
    echo "Would you like to end the currently running preview_build process?" 
    echo -n "[y|n]?"
    read answer
    if [[ ${answer} == y ]] || [[ ${answer} == 'yes' ]] ; 
    then
        echo "Stopping the currently running preview_build process:"
        pkill preview_build 
    else
        echo "Please stop the currently running instance if you would like to start another."
        exit -3
    fi
fi

echo "Current working directory is: `pwd`. Is this the workshop base directory that you want to run preview_build against? "
echo -n "[y|n]?"
read answer

if [[ ${answer} == y ]] || [[ ${answer} == 'yes' ]] ; 
then
    echo "Launching preview_build. Log is at /tmp/previewbuild.out" 
    nohup /usr/local/bin/preview_build 2>&1 > /tmp/previewbuild.out &
else
    echo "Bye"
    exit 0
fi


