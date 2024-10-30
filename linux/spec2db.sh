#!/bin/bash 
################################################################################
# Convert SPECstorage 2020 XML output into usable JSON for import
#
# Author:	kmac@qumulo.com
# Date:		October 22, 2023
#
# Using https://github.com/kislyuk/xq to transcode XML to JSON
#
################################################################################

unset -v WORKLOAD
unset -v INPUT_XML_FILENAME

###
# Parse command line options
###

SHORT=":f:w:,h"
LONG=":filename:,:workload:,help"
OPTS=$(getopt --alternative --name spec2db --options ${SHORT} --longoptions ${LONG} -- "$@") 

Usage()
{
    echo "Usage: spec2db [ -f filename.xml -w workload WORKLOAD | --help ]"
    LAST=1
}
eval set -- "${OPTS}"

while :
do
  case "$1" in
    -f | --filename )
      INPUT_XMLFILE="$2"
      shift 2
      ;;
    -h | --help)
	  Usage 
	  break
      ;;
    -w | --workload)
      WORKLOAD="$2"
      shift 2
      ;;
    --)
      shift;
      break
      ;;
    *)
	  echo "Unexpected option: $1"
	  Usage
	  break 
      ;;
  esac
done
if [[ "$LAST" -eq "1" ]]
then
		echo "exiting..."
		exit 1
fi

BASENAME=`basename $INPUT_XMLFILE`
INPUT_XML_FILENAME="${BASENAME%.*}"
INPUT_XML_EXTENSION="${BASENAME##*.}"	# Need to add error checking to ensure this is an XML file as input 

###
# Verify workload is specified 
###
if [ -z $WORKLOAD ]; then
	echo "SPECstorage 2020 Workload not defined: $WORKLOAD"
	exit -2
fi

################################################################################
# Functions
################################################################################

function runAIimage
{
	printf "\tReading $WORKLOAD results from: $INPUT_XMLFILE\n"

	OUTPUTFILE="${INPUT_XML_FILENAME}_${WORKLOAD}_metrics.csv"

	echo "\"Business Metric\",\"Name\",\"Units\",\"Text\"" > ${OUTPUTFILE}
	cat ${INPUT_XMLFILE} | xq | jq -r '.specSPECstorage2020.results.summary.run.[] | . as {$business_metric} | .metric[] | [$business_metric, ."@name", ."@units", ."#text"] | @csv ' >> ${OUTPUTFILE}

	if [ $? != 0 ]; then
		printf "\tError in execution: $?\n"
		exit 3
	else
		printf "\tExtracted metrics, saving to: ${OUTPUTFILE}\n"
	fi
}


function runSWbuild
{

	printf "\tReading $WORKLOAD results from: $INPUT_XMLFILE\n"

	OUTPUTFILE="${INPUT_XML_FILENAME}_${WORKLOAD}_metrics.csv"

	echo "\"Business Metric\",\"Name\",\"Units\",\"Text\"" > ${OUTPUTFILE}
	cat ${INPUT_XMLFILE} | xq | jq -r '.specSPECstorage2020.results.summary.run.[] | . as {$business_metric} | .metric[] | [$business_metric, ."@name", ."@units", ."#text"] | @csv ' >> ${OUTPUTFILE}

	if [ $? != 0 ]; then
		printf "\tError in execution: $?\n"
		exit 3
	else
		printf "\tExtracted metrics, saving to: ${OUTPUTFILE}\n"
	fi

}


function runGenomics
{
	printf "\tNot implemented yet\n"
	exit 0 
	
}
function startrun
{

	printf "\n<START>\t `date +%Y%m%d:%H%M%S:%Z`\n\n"

}
function endrun
{

	printf "\n<END>\t `date +%Y%m%d:%H%M%S:%Z`\n\n"

}
function validateWorkload
{

	BENCHMARKFOUND=`cat ${INPUT_XMLFILE} | xq | jq -c -r 'limit(1; .specSPECstorage2020.results.summary.run.[]) |{benchmark}' | cut -d '"' -f6`
	if [ ${WORKLOAD} != ${BENCHMARKFOUND} ]; then
		echo "Input file is not from a SPECstorage 2020 ${WORKLOAD} run.  Found: ${BENCHMARKFOUND} "
		exit -2
	fi

}
validateWorkload

################################################################################
# Main
################################################################################

case $WORKLOAD in

  AI_IMAGE)
	startrun
	echo "Spec2DB: Importing SPECstorage 2020 $WORKLOAD metrics into database"
	runAIimage
    ;;

  SWBUILD)
	startrun
	echo "Spec2DB: Importing SPECstorage 2020 $WORKLOAD metrics into database"
	runSWbuild
    ;;

  GENOMICS)
	startrun
	echo "Spec2DB: Importing SPECstorage 2020 $WORKLOAD metrics into database"
	runGenomics
    ;;

  *)
    printf "\nUnknown Workload: $WORKLOAD\n\n"
    exit -1 
    ;;
esac

endrun
exit 0

