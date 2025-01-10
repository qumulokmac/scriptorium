#!/usr/bin/bash
################################################################################
#
# Script Name:  nfs_fio_configurator.sh
# Author:       kmac@qumulo.com
# Date:         August 21st, 2024
# 
# Script to dynamically create the FIO INI file for the hero runs, and 
# supporting DOS scripts needed to mount nfs shares.
#
################################################################################

BASEDIR="/home/qumulo"
NODE_IPS="${BASEDIR}/nodes.conf"

###
# Just need a way to create the nodes.conf dynamically...
###
cat << EOF > "$NODE_IPS"
10.0.2.72
10.0.2.237
10.0.2.153
10.0.3.1
EOF

FIOJOBFILE="${BASEDIR}/fio.jobs"
HERO_IOPS_FILE="${BASEDIR}/hero-nfs-iops.ini"
HERO_TPUT_FILE="${BASEDIR}/hero-nfs-tput.ini"

initialize_files() {
    rm -f "$FIOJOBFILE"
}

mount_nfs_exports() {

    while IFS= read -r ip; do
    	sudo mkdir -p /mnt/fio-node-${ip}
    	sudo mount -t nfs -o tcp,vers=3,nconnect=8 ${ip}:/ /mnt/fio-node-${ip}
    	sudo chown qumulo:qumulo /mnt/fio-node-${ip}
    done < "$NODE_IPS"
}

create_fio_jobfile() {

	local count=0
    while IFS= read -r ip; do
        local myrand="${RANDOM}${RANDOM}${RANDOM}"
        mkdir -p /mnt/fio-node-${ip}/$myrand
        echo "[job${count}]" >> "$FIOJOBFILE"
        echo "directory=/mnt/fio-node-${ip}/$myrand"  >> "$FIOJOBFILE"
        echo "numjobs=1" >> "$FIOJOBFILE"
        echo "" >> "$FIOJOBFILE"
        count=$((count + 1))
    done < "$NODE_IPS"

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
  runtime=1800s
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
  runtime=1800s
  time_based=1

EOF

    cat "$FIOJOBFILE" >> "$HERO_IOPS_FILE"
    cat "$FIOJOBFILE" >> "$HERO_TPUT_FILE"
}

print_scripts() {

    printf "\n\n"
    echo "Hero IOPS FIO Definition file: $HERO_IOPS_FILE"
    echo "Hero Throughput FIO Definition file: $HERO_TPUT_FILE"
}

initialize_files
mount_nfs_exports
create_fio_jobfile
generate_fio_configs
print_scripts

nohup fio hero-nfs-tput.ini 2>&1 >> hero-nfs-tput.out & 
nohup fio hero-nfs-iops.ini 2>&1 >> hero-nfs-iops.out & 



