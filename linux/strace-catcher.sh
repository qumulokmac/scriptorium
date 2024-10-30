
while true
do
    PID=`pgrep ior`
    if [ -z  ${PID} ]
    then
        printf '.'
        sleep 10
    else
        sudo strace -c -p `pgrep ior`
        exit
    fi
done
