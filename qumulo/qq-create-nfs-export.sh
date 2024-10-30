
QNODE=10.0.1.8

wget --no-check-certificate  https://${QNODE}/static/qq

chmod 700 qq

alias qqq="./qq --host ${QNODE}"

qqq login -u admin -p Admin123

qqq nfs_add_export --export-path /io500 --fs-path /io500 --no-restrictions --create-fs-path


