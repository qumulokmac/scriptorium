#!/usr/bin/bash
################################################################################
#
# Script:         adaptive_load_generator.sh
# Last Updated:   Nov 8th, 2024
# Author:         kmac@qumulo.com
#
# Version:        110824.1308
# 
################################################################################

CNQ_FQDN="cnq.qumulo.net"
FIO_RUNTIME=3000

BASEDIR="/home/qumulo"
FIOJOBFILE="/tmp/fio.jobs"
HERO_IOPS_FILE="${BASEDIR}/logs/aloadgen-nfs-iops.ini"
HERO_TPUT_FILE="${BASEDIR}/logs/aloadgen-nfs-tput.ini"
HERO_IOPS_OUT="${BASEDIR}/logs/aloadgen-nfs-iops.out"
HERO_TPUT_OUT="${BASEDIR}/logs/aloadgen-nfs-tput.out"
MAIN_LOGFILE="${BASEDIR}/main.log"
DNS_TOTAL_IPS=$(dig +short $CNQ_FQDN | wc -l)
NPROC_COUNT=$(nproc)

# Ephemeral array that holds unused IP addresses per iteration. 
declare -a available_ips

mkdir -p ${BASEDIR}/logs
echo "$(date) - Current working directory: $(pwd)" >> ${MAIN_LOGFILE}
echo "$(date) - PATH: $PATH" >> ${MAIN_LOGFILE}

if [ "$DNS_TOTAL_IPS" -lt "$NPROC_COUNT" ]; then
    NODE_MOUNT_COUNT=$DNS_TOTAL_IPS
else
    NODE_MOUNT_COUNT=$NPROC_COUNT
fi

echo "$(date) - NODE_MOUNT_COUNT set to ${NODE_MOUNT_COUNT}." >> ${MAIN_LOGFILE}


initialize_files() {
    if [ -e "$FIOJOBFILE" ]; then
        echo "$(date) - Removing $FIOJOBFILE" >> ${MAIN_LOGFILE}
        rm -f "$FIOJOBFILE"
    fi
}

get_unique_ip() {
    if [ ${#available_ips[@]} -eq 0 ]; then
        available_ips=($(dig +short $CNQ_FQDN | shuf))
    fi

    if [ ${#available_ips[@]} -gt 0 ]; then
        local selected_ip="${available_ips[0]}"
        available_ips=("${available_ips[@]:1}")
        echo "$selected_ip"
        return
    else
        echo "$(date) - No more unique IPs available for this iteration." >> ${MAIN_LOGFILE}
        exit 1
    fi
}

umount_nfs_exports() {
    local nfs_mounts
    nfs_mounts=$(mount | grep 'type nfs' | awk '{print $3}')

    for mount_point in $nfs_mounts; do
        local pids
        pids=$(sudo lsof +D "$mount_point" 2>/dev/null | awk '{print $2}' | tail -n +2 | sort -u)

        if [ -n "$pids" ]; then
            for pid in $pids; do
                echo "$(date) - Killing process $pid using $mount_point..." >> ${MAIN_LOGFILE}
                sudo kill -9 "$pid" 2>/dev/null
            done
        fi

        echo "$(date) - Unmounting $mount_point..." >> ${MAIN_LOGFILE}
        sudo umount "$mount_point"

        if [ -d "$mount_point" ]; then
            echo "$(date) - Removing directory $mount_point..." >> ${MAIN_LOGFILE}
            sudo rm -rf "$mount_point"
        else
            echo "$(date) - $mount_point is not a directory or does not exist. Skipping removal." >> ${MAIN_LOGFILE}
        fi

    done

    echo "$(date) - Verifying the /mnt directory" >> ${MAIN_LOGFILE}
    NUMDIRS=$(find /mnt -mindepth 1 -maxdepth 1 -type d)
    if [ -z "$NUMDIRS" ]; then
        echo "$(date) - /mnt is clean" >> ${MAIN_LOGFILE}
    else
        echo "$(date) - /mnt is dirty:" >> ${MAIN_LOGFILE}
        echo "$NUMDIRS" >> "$HERO_IOPS_OUT"
        for dir in $NUMDIRS
        do
            echo "Attempting to cleanse $dir" >> ${MAIN_LOGFILE}
            sudo rmdir "$dir"
            if [ $? -ne 0 ]; then
                echo "$(date) - could not cleanse $dir: $?" >> ${MAIN_LOGFILE}
                exit 1
            fi
        done
    fi
    echo "Shotgunning stubborn fio procs..." >> ${MAIN_LOGFILE}
    sudo pkill -9 fio  >> ${MAIN_LOGFILE} 
}

mount_nfs_exports() {
    umount_nfs_exports

    local count=0
    while [ $count -lt $NODE_MOUNT_COUNT ]; do
        local ip
        ip=$(get_unique_ip)
        echo "$(date) - Using node IP $ip" >> ${MAIN_LOGFILE}
        local MNTPNT
        MNTPNT="/mnt/fio-node-${ip}"

        if [ -e "$MNTPNT" ]; then
            echo "$(date) - Mountpoint directory ${MNTPNT} ALREADY EXISTS." >> ${MAIN_LOGFILE}
        else
            echo "$(date) - Creating directory $MNTPNT..." >> ${MAIN_LOGFILE}
            sudo mkdir -p "$MNTPNT"
            sudo chown qumulo:qumulo "$MNTPNT"
        fi

        echo "$(date) - Mounting NFS export from ${ip} to $MNTPNT..." >> ${MAIN_LOGFILE}
        sudo mount -t nfs -o tcp,vers=3,nconnect=16 ${ip}:/ $MNTPNT
        sudo chown qumulo:qumulo "$MNTPNT"
        count=$((count + 1))

        if [ $count -eq $NODE_MOUNT_COUNT ]; then
            break
        fi
        echo "$count mounts done" >> ${MAIN_LOGFILE}
    done
}

create_fio_jobfile() {
    local count=1

    for mntpnt in $(mount | grep 'type nfs' | awk '{print $3}'); do
        local myrand
        myrand="${RANDOM}${RANDOM}${RANDOM}"
        mkdir -p "${mntpnt}/$myrand"

        echo "[job${count}_tput]" >> "$FIOJOBFILE"
        echo "directory=${mntpnt}/$myrand" >> "$FIOJOBFILE"
        echo "numjobs=1" >> "$FIOJOBFILE"
        echo "" >> "$FIOJOBFILE"

        # Stop after referencing the required number of mount points
        if [ $count -eq ${NODE_MOUNT_COUNT} ]; then
            break
        fi
        count=$((count + 1))
    done
}

generate_fio_configs() {
    cat << EOF > "$HERO_IOPS_FILE"
[global]
  blocksize=4KiB
  direct=1
  filesize=100MiB
  iodepth=32
  ioengine=libaio
  kb_base=1000
  numjobs=16
  rw=read
  runtime=${FIO_RUNTIME}s
  time_based=1

EOF

    cat << EOF > "$HERO_TPUT_FILE"
[global]
  blocksize=1MiB
  direct=1
  filesize=1GiB
  iodepth=32
  ioengine=libaio
  kb_base=1000
  numjobs=16
  rw=read
  runtime=${FIO_RUNTIME}s
  time_based=1

EOF

    grep '^\[job[0-9]*_iops\]' -A 3 "$FIOJOBFILE" | sed '/^--$/d' >> "$HERO_IOPS_FILE"
    grep '^\[job[0-9]*_tput\]' -A 3 "$FIOJOBFILE" | sed '/^--$/d' >> "$HERO_TPUT_FILE"

}

start_fio() {
    local config_file="$1"
    local output_file="$2"
    local num_jobs="$3"

    echo "$(date) - Starting $num_jobs FIO jobs with config $config_file." >> "$MAIN_LOGFILE"
    echo "$(date) - Output file: $output_file" >> "$MAIN_LOGFILE"

    for (( i=0; i<num_jobs; i++ )); do
        echo "$(date) - Running: sudo nohup stdbuf -oL fio $config_file >> $output_file 2>&1 &" >> "$MAIN_LOGFILE"
        sudo nohup stdbuf -oL fio "$config_file" >> "$output_file" 2>&1 &
        pids+=($!)
    done

    echo "$(date) - FIO processes started with PIDs: ${pids[*]}" >> "$MAIN_LOGFILE"
    echo "${pids[@]}"
}

check_fio_processes() {
    local pids=("$@")
    local all_done

    while true; do
        all_done=true
        for pid in "${pids[@]}"; do
            if ps -p $pid > /dev/null; then
                all_done=false
                break
            fi
        done

        if [ "$all_done" = true ]; then
            echo "$(date) - All fio processes completed." >> ${MAIN_LOGFILE}
            break
        fi

        echo "$(date) - Waiting for fio processes to finish..." >> ${MAIN_LOGFILE}
        sleep 5
    done
}

initialize_files
mount_nfs_exports
create_fio_jobfile
generate_fio_configs

NUM_IOPS_JOBS=$((NODE_MOUNT_COUNT / 2))
NUM_TPUT_JOBS=$((NODE_MOUNT_COUNT / 2))

while true; do
    pids=()
    # pids+=($(start_fio "$HERO_IOPS_FILE" "$HERO_IOPS_OUT" "$NUM_IOPS_JOBS"))
    pids+=($(start_fio "$HERO_TPUT_FILE" "$HERO_TPUT_OUT" "$NUM_TPUT_JOBS"))

    echo "$(date) - Started FIO processes, waiting ${FIO_RUNTIME} seconds." >> "$MAIN_LOGFILE"
    sleep ${FIO_RUNTIME}
    check_fio_processes "${pids[@]}"
done

exit 0


