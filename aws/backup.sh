#!/bin/bash -v
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

BASEFILENAME="`whoami`-`hostname`-`date +%Y%m%d-%H%M%S`-backup"
ARCHIVE_DIR="/Users/mcaws/Backups"
# ARCHIVE_DIR='/Volumes/KMACTN'
LOCAL_TARGET="${ARCHIVE_DIR}"
RETENTION='+30'

tar -zcvvf "${LOCAL_TARGET}/${BASEFILENAME}.tgz" ~/Documents ~/Scripts >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1 

echo "The following backups older than $RETENTION days will be deleted:"  >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1
find "${ARCHIVE_DIR}" -type f -mtime ${RETENTION} -name "*-backup.tgz" -exec ls -l {}  \; >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1

exit 

echo "" >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1

echo "Removing backups older than $RETENTION days"  >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1
find "${ARCHIVE_DIR}" -type f -mtime ${RETENTION} -name "*-backup.tgz" -exec unlink {} \; >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1

echo "" >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1

echo "Remaining backup archives in ${ARCHIVE_DIR}" >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1
ls -ltr "${ARCHIVE_DIR}"  >> /Users/mcaws/logs/${BASEFILENAME}.log 2>&1

# echo "Now copying the tarball to S3" 
# nohup aws s3 cp "${LOCAL_TARGET}/${BASEFILENAME}.tgz"  s3://kmacs.backup/

###
# command to sync everything induvidually; takes days.
###
# nohup aws s3 sync . s3://kmacs.backup/ > logs/full_s3_sync.out &
