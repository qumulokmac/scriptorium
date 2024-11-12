#!/usr/bin/bash
cd /home/qumulo
nohup sudo ./adaptive_load_generator.sh > /tmp/loadgen.out 2>&1 &
