#!/bin/bash 
################################################################################
#
# make-batchs.sh
#
# Author:	kmac@qumulo.com
# Date:		12/15/2023
#
# Wrapper script to create batch and FIO ini files
#
################################################################################

#############################
# Configurable variables
#############################
CPUS_PER_WORKER=16
WORKERS_CONF="workers.conf"
FIO_TEMPLATE="mrcoop-50rw.ini"
OUTPUTDIR="output"
#############################

DTS=`date +%Y%m%d%H%m%S` 
declare -a HOSTS=(`cat $WORKERS_CONF`)
declare -i FIO_JOBID=0

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do 
  echo -n "${HOSTS[$hostindex]}"
  for (( numi=0; numi<${CPUS_PER_WORKER}; numi++ ))
	do
    BAT_FILE="runfio-${HOSTS[$hostindex]}-${DTS}-${numi}.bat"
    FIO_LOGFILE="fio-${HOSTS[$hostindex]}-${DTS}-${numi}.log"
    FIO_INI_FILENAME="${HOSTS[$hostindex]}-${DTS}-${numi}-${FIO_TEMPLATE}"
    FIO_JOBID=0
    while [ $FIO_JOBID -ne ${#HOSTS[@]} ]
    do
      cp -p ${FIO_TEMPLATE} "${OUTPUTDIR}/${FIO_INI_FILENAME}"
      for DRVLTR in `jot -r -c ${#HOSTS[@]} F U`
      do
            FIO_JOBID=$((FIO_JOBID+1))
            echo "[job$FIO_JOBID]" >> "${OUTPUTDIR}/${FIO_INI_FILENAME}"
            echo "directory=${DRVLTR}\:FIODATA\\-${HOSTS[$hostindex]}"  >> "${OUTPUTDIR}/${FIO_INI_FILENAME}"
            echo "numjobs=1"  >> "${OUTPUTDIR}/${FIO_INI_FILENAME}"
            echo ""  >> "${OUTPUTDIR}/${FIO_INI_FILENAME}"
      done
      echo "# Batch File $BAT_FILE " >> "${OUTPUTDIR}/${BAT_FILE}"
      echo "" >> "${OUTPUTDIR}/${BAT_FILE}"
      echo "MKDIR F:\FIODATA\\${HOSTS[$hostindex]} "  >> "${OUTPUTDIR}/${BAT_FILE}"
      echo -n 'C:\fio\fio-master\fio --thread --output=F:\logs\'  >> "${OUTPUTDIR}/${BAT_FILE}"
      echo "${FIO_LOGFILE} C:\FIO\\${FIO_INI_FILENAME}" >> "${OUTPUTDIR}/${BAT_FILE}"
      echo -n "."
    done
	done
  echo ""
done
echo ""

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do 
  SPAWNFILE="${OUTPUTDIR}/spawn-fio-procs-${HOSTS[$hostindex]}.ps1"
  echo '$batchScripts = @(' >>${SPAWNFILE}
  
  declare -i count=1
  for file in `ls -1 ${OUTPUTDIR}/runfio-${HOSTS[$hostindex]}*.bat | sort -V`
  do
    echo -n "\"C:\FIO\\$file\""  >>${SPAWNFILE}
    if [ $count -lt ${#HOSTS[@]} ]
    then
      echo ',' >>${SPAWNFILE}
    else
      echo ')'  >>${SPAWNFILE}
    fi
    count=$((count+1))
  done
  cat >> "${SPAWNFILE}" <<EOFF

\$jobs = @()
foreach (\$scriptPath in \$batchScripts) {
    \$job = Start-Job -ScriptBlock {
        param(\$scriptPath)
        & \$scriptPath
    } -ArgumentList \$scriptPath
    \$jobs += \$job
}

Wait-Job -Job \$jobs
 
\$results = Receive-Job -Job \$jobs

foreach (\$result in \$results) {
    Write-Output "Job Result: \$result"
}

Remove-Job -Job \$jobs 

EOFF

done

exit 0 
