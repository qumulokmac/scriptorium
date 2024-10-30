#!/bin/bash
######################################################################
# Spec Harness Ubuntu Custom Data Script
#
# kmac@qumulo.com
# May 8th, 2024
######################################################################

###
# Update apt and install packages
###
apt -y  update
apt -y  upgrade
apt-get -y dist-upgrade
apt install -y nfs-common make gcc automake autoconf libtool m4 python3-pip selinux-utils gpg build-essential manpages-dev binutils coreutils curl jq wget duf git gzip lsof netcat-openbsd nfs-common nmap pssh screen strace tcpdump unzip util-linux vim ncal python3-pip

apt-get install -y python3-pip build-essential libssl-dev libffi-dev python3-dev python3-venv default-jre

python3 -m pip install --upgrade pip
python3 -m pip install matplotlib six pyparsing
ufw disable

###
# Qumulo account
###

useradd -m -s /bin/bash qumulo
echo "StrictHostKeyChecking accept-new" >> /home/qumulo/.ssh/ssh_config
chown -R qumulo:qumulo /home/qumulo
chmod 0600 /home/qumulo/.ssh/ssh_config
chmod 700 /home/qumulo/.ssh

echo "qumulo - nofile 50000" >> /etc/security/limits.conf
echo "qumulo - noproc 50000" >> /etc/security/limits.conf
echo "qumulo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-cloud-init-users

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
apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

apt-get -y update
apt-get -y install azure-cli

