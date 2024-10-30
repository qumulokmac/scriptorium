#!/bin/bash
######################################################################
# Spec Harness Ubuntu Custom Data Script
#
# kmac@qumulo.com
# May 8th, 2024
######################################################################

###
# Update and install packages
###
dnf -y update
dnf -y install nfs-utils python3-pip policycoreutils-python-utils gnupg2 binutils coreutils curl jq wget git gzip lsof nmap-ncat nmap strace tcpdump unzip util-linux vim-enhanced net-tools
dnf -y groupinstall "Development Tools" "System Tools"

python3 -m pip install matplotlib six pyparsing

echo "*       hard    nofile  10000" >> /etc/security/limits.conf
echo "*       hard    noproc  10000" >> /etc/security/limits.conf

###
# Update sysctl settings
###

(cat << _EOF_
###
# Spec Storage 2020 Qumulo sysctls
# kmac@qumulo.com 5/8/2024
###
net.core.wmem_max = 16777216
net.core.wmem_default = 16777216
net.core.rmem_max = 16777216
net.core.rmem_default = 16777216
net.ipv4.tcp_rmem = 1048576 8388608 16777216
net.ipv4.tcp_wmem = 1048576 8388608 16777216
net.core.optmem_max = 2048000
net.core.somaxconn = 65535
net.ipv4.tcp_mem = 4096 89600 4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.route.flush = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.core.netdev_max_backlog = 300000
vm.dirty_expire_centisecs = 100
vm.dirty_writeback_centisecs = 100
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
fs.file-max = 2097152
_EOF_
) >> /etc/sysctl.conf

###
# Azure CLI
###

rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm

echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/dnfrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/dnf.repos.d/azure-cli.repo

dnf install azure-cli

###
# Disable the local firewall
###
systemctl stop firewalld
systemctl disable firewalld

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


###
# Python 3.8
###
dnf -y  install epel-release
dnf -y install python38

sudo alternatives --set python /usr/bin/python3.8
sudo ln -s /usr/bin/pip3 /usr/bin/pip

pip install qumulo-api
python3 -m pip install --upgrade pip

python3 -m pip install matplotlib six pyparsing

pip install pyyaml matplotlib





