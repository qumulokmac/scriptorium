#!/opt/homebrew/bin/bash
################################################################################
#
# Script Name:  smb_fio_configurator.sh
# Author:       kmac@qumulo.com
# Date:         August 21st, 2024
# 
# Script to dynamically create the FIO INI file for the hero runs, and 
# supporting DOS scripts needed to mount SMB shares.
#
################################################################################

BASEDIR="/tmp"

NODE_IPS="${BASEDIR}/nodes.conf"
MOUNTSCRIPT="${BASEDIR}/mountscript.cmd"
MKDIRFILE="${BASEDIR}/mkdir-windows.cmd"
FIOJOBFILE="${BASEDIR}/fio.jobs"
HERO_IOPS_FILE="${BASEDIR}/hero-smb-iops.ini"
HERO_TPUT_FILE="${BASEDIR}/hero-smb-tput.ini"

initialize_files() {
    rm -f "$FIOJOBFILE" "$MKDIRFILE" "$MOUNTSCRIPT"
}

generate_mount_script() {
    local drive_letter="F"
    while IFS= read -r ip; do
        echo "net use ${drive_letter}: \\\\$ip\\Files /user:admin Qumulo1! /persistent:yes" >> "$MOUNTSCRIPT"
        drive_letter=$(echo "$drive_letter" | tr "A-Z" "B-ZA" | head -c 1)
    done < "$NODE_IPS"
}

generate_mkdir_and_fiojobs() {
    local drive_letter="F"
    local count=0
    while IFS= read -r ip; do
        local myrand="${RANDOM}${RANDOM}${RANDOM}"
        echo "MKDIR ${drive_letter}:\\FIODATA\\${myrand}" >> "$MKDIRFILE"
        echo "[job${count}]" >> "$FIOJOBFILE"
        echo "directory=${drive_letter}\\:FIODATA\\${myrand}" >> "$FIOJOBFILE"
        echo "numjobs=1" >> "$FIOJOBFILE"
        echo "" >> "$FIOJOBFILE"
        drive_letter=$(echo "$drive_letter" | tr "A-Z" "B-ZA" | head -c 1)
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
  ioengine=windowsaio
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
  ioengine=windowsaio
  kb_base=1000
  numjobs=16
  rw=read
  runtime=120s
  time_based=1

EOF

    cat "$FIOJOBFILE" >> "$HERO_IOPS_FILE"
    cat "$FIOJOBFILE" >> "$HERO_TPUT_FILE"
}

print_scripts() {

    printf '%*s\n' 80 '' | tr ' ' '#'
    printf "# MS DOS SMB MOUNT SCRIPT"
    printf "\n"
    printf '%*s\n' 80 '' | tr ' ' '#'
    printf "\n"
    cat "$MOUNTSCRIPT"
    printf "\n\n"
    
    printf '%*s\n' 80 '' | tr ' ' '#'
    printf "# MS DOS MKDIR SCRIPT"
    printf "\n"
    printf '%*s\n' 80 '' | tr ' ' '#'
    printf "\n"
    cat "$MKDIRFILE"

    printf "\n\n"
    echo "Hero IOPS FIO Definition file: $HERO_IOPS_FILE"
    echo "Hero Throughput FIO Definition file: $HERO_TPUT_FILE"
}

initialize_files
generate_mount_script
generate_mkdir_and_fiojobs
generate_fio_configs
print_scripts