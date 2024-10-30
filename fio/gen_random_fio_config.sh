#!/bin/bash

CONFIG_FILE="fio_config.ini"
NUM_JOBS=256
TOTAL_RUNTIME=600 # seconds
MAX_PERCENT_READ=25

# Function to generate a random integer within a range
random_int() {
    local min=$1
    local max=$2
    echo $(($min + RANDOM % ($max - $min + 1)))
}

# Function to generate a random runtime
random_runtime() {
    echo $(random_int 60 180) # Random runtime between 60 and 180 seconds
}

# Function to generate random percentages for read and write
random_percentages() {
    local percent_write=$(random_int 60 100) # Random write percentage between 60% and 100%
    local max_percent_read=$((100 - MAX_PERCENT_READ)) # Maximum value for percent_read
    local percent_read=$(random_int 0 $max_percent_read) # Random read percentage between 0% and max_percent_read
    echo "$percent_read $((100 - $percent_read))"
}

# Generate the configuration file
echo "[global]" > "$CONFIG_FILE"
echo "numjobs=$NUM_JOBS" >> "$CONFIG_FILE"
echo "rw=randrw" >> "$CONFIG_FILE"
echo "rwmixread=70" >> "$CONFIG_FILE"
echo "direct=1" >> "$CONFIG_FILE"
echo "blocksize=4KiB" >> "$CONFIG_FILE"
echo "runtime=$TOTAL_RUNTIME"s >> "$CONFIG_FILE"
echo "filesize=1GiB" >> "$CONFIG_FILE"
echo "iodepth=16" >> "$CONFIG_FILE"
echo "kb_base=1024" >> "$CONFIG_FILE"
echo "fallocate=none" >> "$CONFIG_FILE"
echo "time_based=1" >> "$CONFIG_FILE"
echo "" >> "$CONFIG_FILE"

# Generate job configurations
for ((i = 1; i <= NUM_JOBS; i++)); do
    echo "[job$i]" >> "$CONFIG_FILE"
    echo "startdelay=randwrite" >> "$CONFIG_FILE"
    echo "runtime=$(random_runtime)s" >> "$CONFIG_FILE"
    echo "stonewall" >> "$CONFIG_FILE"
    percentages=$(random_percentages)
    echo "percent_read=${percentages%% *}" >> "$CONFIG_FILE"
    echo "percent_write=${percentages##* }" >> "$CONFIG_FILE"
    echo "thinktime=randwrite" >> "$CONFIG_FILE"
    echo "random_distribution=pareto:0.5" >> "$CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
done

echo "Configuration file '$CONFIG_FILE' created."

