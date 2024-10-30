#!/bin/bash

echo "=== Security Applications and Services Report ==="

# List common security applications that may be installed
echo "Checking for common security applications (e.g., firewall, antivirus)..."
security_apps=("ufw" "iptables" "firewalld" "fail2ban" "apparmor" "selinux" "clamav" "auditd")
for app in "${security_apps[@]}"; do
    if command -v $app &> /dev/null; then
        echo " - $app is installed and may be running."
    fi
done

# Check status of common security services
echo "Checking status of common security services..."
security_services=("ufw" "firewalld" "fail2ban" "apparmor" "clamav-daemon" "auditd")
for service in "${security_services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo " - $service is currently active. Consider stopping it if not needed."
    else
        echo " - $service is not running."
    fi
done

# List open network ports
echo "Checking open network ports..."
open_ports=$(netstat -tuln | grep LISTEN)
if [ -n "$open_ports" ]; then
    echo "Open network ports:"
    echo "$open_ports"
    echo " - Review open ports and consider closing them if they are not required for benchmarking."
else
    echo " - No open network ports detected."
fi

# Check for active SSH connections
echo "Checking for active SSH sessions..."
ssh_connections=$(who | grep -i ssh)
if [ -n "$ssh_connections" ]; then
    echo "Active SSH sessions detected:"
    echo "$ssh_connections"
    echo " - Consider closing SSH sessions if remote access is not needed during benchmarking."
else
    echo " - No active SSH sessions detected."
fi

# Suggest commands for stopping services
echo "=== Suggested Commands to Stop Services ==="
for service in "${security_services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "To stop $service: sudo systemctl stop $service"
    fi
done

echo "=== Note ==="
echo "Ensure that stopping any service won't disrupt necessary functionality or critical security."