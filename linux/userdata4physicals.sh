#!/bin/bash
################################################################################
#
# Name:                 userdata4physicals.sh
# Last Updated:         Oct 26th, 2024
# Author:               kmac@qumulo.com
#
################################################################################

LOG_FILE="/var/log/userdata.log"
RM_SECURITY_TOOLS_LOG_FILE="/var/log/remove_security_tools.log"

log_message() {
    local MESSAGE=$1
    echo "#############################" | tee -a $LOG_FILE
    echo "#  $(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" | tee -a $LOG_FILE
    echo "#############################" | tee -a $LOG_FILE
}

stop_service_if_running() {
    local service=$1
    if systemctl list-units --type=service --all | grep -q "$service"; then
        if systemctl is-active --quiet $service; then
            log_message "Stopping $service service using systemctl..."
            systemctl stop $service >> $LOG_FILE 2>&1
            log_message "$service service stopped successfully."
        else
            log_message "$service service is not running (systemctl)."
        fi
    elif service --status-all | grep -q "$service"; then
        if service $service status > /dev/null 2>&1; then
            log_message "Stopping $service service using service..."
            service $service stop >> $LOG_FILE 2>&1
            log_message "$service service stopped successfully."
        else
            log_message "$service service is not running (service)."
        fi
    else
        log_message "$service service not found."
    fi
}

remove_package_if_installed() {
    local pkg=$1
    if dpkg -l | grep -q "^ii.*$pkg"; then
        log_message "Initiating removal of $pkg..."
        stop_service_if_running $pkg
        log_message "Removing $pkg..."
        apt-get remove --purge -y $pkg >> $LOG_FILE 2>&1
        log_message "$pkg removed successfully."
    else
        log_message "$pkg is not installed."
    fi
}

update_limits_conf() {
    log_message "Starting update_limits_conf"
    echo "Increasing max openfile limits in /etc/security/limits.conf..." | tee -a $LOG_FILE
    grep -q "soft nofile 65535" /etc/security/limits.conf || echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
    grep -q "hard nofile 65535" /etc/security/limits.conf || echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf

    echo "Updating /etc/pam.d/common-session..." | tee -a $LOG_FILE
    grep -q "session required pam_limits.so" /etc/pam.d/common-session || echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session

    echo "Updating /etc/pam.d/common-session-noninteractive..." | tee -a $LOG_FILE
    grep -q "session required pam_limits.so" /etc/pam.d/common-session-noninteractive || echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive

    echo "Updating /etc/systemd/system.conf and /etc/systemd/user.conf..." | tee -a $LOG_FILE
    sudo sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' /etc/systemd/system.conf
    sudo sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' /etc/systemd/user.conf
    log_message "Completed update_limits_conf"
}

disable_selinux() {
    log_message "Starting disable_selinux"
    if [ -f /etc/selinux/config ]; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi
    log_message "Completed disable_selinux"
}

remove_security_tools() {
    log_message "Starting remove_security_tools"
    remove_package_if_installed ufw
    remove_package_if_installed iptables
    remove_package_if_installed firewalld
    remove_package_if_installed clamav-freshclam
    remove_package_if_installed clamav
    remove_package_if_installed chkrootkit
    remove_package_if_installed rkhunter
    remove_package_if_installed apparmor
    remove_package_if_installed selinux
    remove_package_if_installed fail2ban
    remove_package_if_installed tripwire
    remove_package_if_installed auditd
    remove_package_if_installed suricata
    remove_package_if_installed snort
    remove_package_if_installed ossec-hids
    remove_package_if_installed lynis
    remove_package_if_installed psad

    echo "Cleaning up..." | tee -a $LOG_FILE
    apt-get autoremove -y >> $LOG_FILE 2>&1
    apt-get clean >> $LOG_FILE 2>&1
    log_message "Completed remove_security_tools"
}

disable_ipv6() {
    log_message "Starting disable_ipv6"

    cat <<EOF > /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

    sysctl --system | tee -a $LOG_FILE

    sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& ipv6.disable=1/' /etc/default/grub
    update-grub | tee -a $LOG_FILE

    log_message "Completed disable_ipv6"
}

enable_jumbo_frames() {
    log_message "Starting enable_jumbo_frames"

    INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
    if [ -n "$INTERFACE" ]; then
        ip link set dev $INTERFACE mtu 9000 || true
    else
        log_message "No default interface found, unable to set MTU"
    fi

    log_message "Completed enable_jumbo_frames"
}

configure_ntp() {
    log_message "Starting configure_ntp"
    apt-get install -y chrony | tee -a $LOG_FILE
    cat <<EOF > /etc/chrony/chrony.conf
server 169.254.169.123 prefer iburst
EOF
    systemctl restart chrony | tee -a $LOG_FILE
    log_message "Completed configure_ntp"
}

create_admin_user() {
    log_message "Starting create_admin_user"
    local admin_user="qumulo"
    useradd -m -s /bin/bash $admin_user
    echo 'PS1="\u@$(hostname -f):\w\$ "' >> /home/$admin_user/.bashrc
    mkdir -p /home/$admin_user/.ssh
    cp /home/ubuntu/.ssh/authorized_keys /home/$admin_user/.ssh/authorized_keys
    chown -R $admin_user:$admin_user /home/$admin_user/.ssh
    chmod 700 /home/$admin_user/.ssh
    chmod 600 /home/$admin_user/.ssh/authorized_keys
    log_message "Created admin user $admin_user and configured SSH."
    echo "$admin_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$admin_user
    log_message "Completed create_admin_user"
}

update_and_install_packages() {
    log_message "Starting update_and_install_packages"
    apt -y update | tee -a $LOG_FILE
    apt -y upgrade | tee -a $LOG_FILE
    apt -y install make gcc automake autoconf libtool m4 selinux-utils gpg manpages-dev binutils coreutils curl jq wget duf git gzip lsof nfs-common pssh screen strace tcpdump unzip util-linux vim ncal build-essential libssl-dev libffi-dev software-properties-common net-tools python3-apt | tee -a $LOG_FILE
    apt -y autoremove | tee -a $LOG_FILE
    log_message "Completed update_and_install_packages"
}

update_sysctl_settings() {
    log_message "Starting update_sysctl_settings"
    cat << _EOF_ >> /etc/sysctl.conf
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

    log_message "Sysctl settings updated successfully."
    log_message "Completed update_sysctl_settings"
}

disable_ssh_agent_forwarding() {
    log_message "Starting disable_ssh_agent_forwarding"
    sed -i 's/#AllowAgentForwarding yes/AllowAgentForwarding no/g' /etc/ssh/sshd_config
    sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding no/g' /etc/ssh/sshd_config
    log_message "Completed disable_ssh_agent_forwarding"
}

reboot_system() {
    log_message "Starting reboot_system"
    echo "Rebooting" | tee -a $LOG_FILE
    reboot
    log_message "Completed reboot_system"
}

main() {
    log_message "Starting main script"

    disable_selinux
    remove_security_tools
    disable_ipv6
    enable_jumbo_frames
    configure_ntp
    create_admin_user
    update_and_install_packages
    update_sysctl_settings
    update_limits_conf
    # reboot_system

    log_message "Completed main script"
}

main
