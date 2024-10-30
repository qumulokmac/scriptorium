#!/usr/bin/bash
################################################################################
#
# Script: monclient-logger.sh
# Author: kmac@qumulo.com
# Date:   May 5th, 2024
#         
# Purpose: Ubuntu based system metrics collection script
#
# Note:   Change OUTPUTDIR to a directory you wish to store the output files
#
# Below is a simple bash wrapper script you can use to invoke this script every 
# SLEEP_INTERVAL seconds
# 
################################################################################
#!/usr/bin/bash
#
# SLEEP_INTERVAL=300
# 
# while true
# do
#   ~/tools/monclient-logger.sh
#   sleep $SLEEP_INTERVAL
# done
# 
################################################################################

OUTPUTDIR="/home/qumulo/logs/monclient"
mkdir -p $OUTPUTDIR
DTS=`date +%Y%m%d%H%M%Z`
HOST=`hostname`

OPENFILES=`sudo lsof -u qumulo | wc -l`
echo "${HOST}:${DTS}:${OPENFILES}" >> ${OUTPUTDIR}/openfiles

for metric in loadavg uptime mounts stat meminfo vmstat
do
  echo "####################################" >> ${OUTPUTDIR}/${metric}
  echo "# $HOST $metric " >> ${OUTPUTDIR}/${metric}
  echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/${metric}
  echo "####################################" >> ${OUTPUTDIR}/${metric}
  cat /proc/${metric} >> ${OUTPUTDIR}/${metric}
done

echo "####################################" >> ${OUTPUTDIR}/pressure-io
echo "# $HOST pressure-io " >> ${OUTPUTDIR}/pressure-io
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/pressure-io
echo "####################################" >> ${OUTPUTDIR}/pressure-io
cat /proc/pressure/io >> ${OUTPUTDIR}/pressure-io

echo "####################################" >> ${OUTPUTDIR}/pressure-cpu
echo "# $HOST pressure-cpu " >> ${OUTPUTDIR}/pressure-cpu
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/pressure-cpu
echo "####################################" >> ${OUTPUTDIR}/pressure-cpu
cat /proc/pressure/cpu >> ${OUTPUTDIR}/pressure-cpu

echo "####################################" >> ${OUTPUTDIR}/pressure-mem
echo "# $HOST pressure-mem " >> ${OUTPUTDIR}/pressure-mem
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/pressure-mem
echo "####################################" >> ${OUTPUTDIR}/pressure-mem
cat /proc/pressure/memory >> ${OUTPUTDIR}/pressure-mem

echo "####################################" >> ${OUTPUTDIR}/procs-n-threads-qumulo
echo "# $HOST ps -u qumulo -L " >> ${OUTPUTDIR}/procs-n-threads-qumulo
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/procs-n-threads-qumulo
echo "####################################" >> ${OUTPUTDIR}/procs-n-threads-qumulo
ps -u qumulo -Lf >> ${OUTPUTDIR}/procs-n-threads-qumulo

echo "####################################" >> ${OUTPUTDIR}/nfsiostat
echo "# $HOST nfsiostat " >> ${OUTPUTDIR}/nfsiostat
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/nfsiostat
echo "####################################" >> ${OUTPUTDIR}/nfsiostat
nfsiostat -s >> ${OUTPUTDIR}/nfsiostat

echo "####################################" >> ${OUTPUTDIR}/nfsstat
echo "# $HOST nfsstat " >> ${OUTPUTDIR}/nfsstat
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/nfsstat
echo "####################################" >> ${OUTPUTDIR}/nfsstat
nfsstat -nl >> ${OUTPUTDIR}/nfsstat

echo "####################################" >> ${OUTPUTDIR}/nfsstat-rpc
echo "# $HOST nfsstat-rpc " >> ${OUTPUTDIR}/nfsstat-rpc
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/nfsstat-rpc
echo "####################################" >> ${OUTPUTDIR}/nfsstat-rpc
nfsstat -r >> ${OUTPUTDIR}/nfsstat-rpc

echo "####################################" >> ${OUTPUTDIR}/mountstats
echo "# $HOST mountstats " >> ${OUTPUTDIR}/mountstats
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/mountstats
echo "####################################" >> ${OUTPUTDIR}/mountstats
cat /proc/self/mountstats >> ${OUTPUTDIR}/mountstats


echo "####################################" >> ${OUTPUTDIR}/mountstats
echo "# $HOST mountstats " >> ${OUTPUTDIR}/mountstats
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/mountstats
echo "####################################" >> ${OUTPUTDIR}/mountstats
cat /proc/self/mountstats >> ${OUTPUTDIR}/mountstats


echo "####################################" >> ${OUTPUTDIR}/duf
echo "# $HOST duf " >> ${OUTPUTDIR}/duf
echo "# Date/Time: $DTS " >> ${OUTPUTDIR}/duf
echo "####################################" >> ${OUTPUTDIR}/duf
duf -hide network -json >> ${OUTPUTDIR}/mountstats


exit 0
