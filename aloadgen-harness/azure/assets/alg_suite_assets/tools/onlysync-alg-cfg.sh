


parallel-scp -h ~/conf/workers.conf /home/qumulo/adaptive_load_generator.sh /home/qumulo/adaptive_load_generator.sh
parallel-scp -h ~/conf/workers.conf /home/qumulo/start_load.sh /home/qumulo/start_load.sh

parallel-ssh  -h ~/conf/workers.conf 'mkdir -p tools' 
parallel-scp -h ~/conf/workers.conf /home/qumulo/tools/* /home/qumulo/tools
