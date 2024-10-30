#!/usr/bin/bash
################################################################################
#
# Name:    start_benchmark.sh
# Author:  kmac@qumulo.com
# Date:    April 1st, 2024
#
################################################################################

usage() {
    echo "Usage: $0 -s SUFFIX" 1>&2
    exit 1
}

while getopts ":s:" opt; do
    case "${opt}" in
        s)
            SUFFIX=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $SUFFIX ]]; then
    usage
fi

DTS=$(date +%Y%m%d-%H%M%Z)

RESULTS_DIR="/home/qumulo/spec/SPECExecutable/results"
if [ -e "$RESULTS_DIR" ]; then
    mv "$RESULTS_DIR" "$RESULTS_DIR.previous_${DTS}"
fi

echo "Starting Benchmark for ${SUFFIX} at ${DTS}"
cd ~/spec/SPECExecutable || exit 1
nohup python3 SM2020 -r "sfs_${SUFFIX}" -s "${SUFFIX}" >> "/home/qumulo/logs/${SUFFIX}_${DTS}_STDOUT.log" 2>&1 &

for worker in $(< ~/tools/workers.conf); do
    if ssh -v -o ConnectTimeout=10 "$worker" true; then
        NUMPROCS=$(ssh -v "$worker" "pgrep -c monclient")
        if [[ "$NUMPROCS" -eq "0" ]]; then
            echo "Starting monclient.sh on $worker"
            ssh "$worker" "nohup /home/qumulo/tools/monclient.sh >/dev/null 2>&1 &"
        fi
    else
        echo "Failed to SSH to $worker"
    fi
done

echo "Launching monclient.sh on Maestro"
nohup ~/tools/monclient.sh > ~/logs/monclient/monclient-stdout.log &
