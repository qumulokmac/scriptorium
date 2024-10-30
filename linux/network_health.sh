# Function to run the script on a local or remote machine
run_script() {
    local hostname=$1

    if [ "$remote_run" = true ]; then
        # Copy the script to the remote server
        scp "$0" "${hostname}:/tmp/network_health.sh"
        # Execute the script on the remote server
        ssh "$hostname" "bash /tmp/network_health.sh -o /tmp/network_health_report.log -p"
    else
        # Local execution
        # Check for and install required packages
        required_packages=("iproute2" "iftop")
        for package in "${required_packages[@]}"; do
          if ! dpkg -s "$package" &> /dev/null; then
            echo "Installing $package..."
            sudo apt-get install -y "$package"
          fi
        done

        # Ensure nstat command is available
        if ! command -v nstat &> /dev/null; then
            echo "nstat could not be found. Please ensure the iproute2 package is installed correctly."
            exit 1
        fi

        # Get current timestamp and hostname
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local_hostname=$(hostname -s)

        # Redirect output to a file if specified, unless printing to STDOUT
        if [ -n "$output_file" ] && [ "$print_stdout" = false ]; then
            exec > >(tee -a "$output_file") 2>&1
        fi

        # Display header
        echo ""
        echo "################################################################################"
        echo "# Network Health Report for $local_hostname - $timestamp"
        echo "################################################################################"
        echo ""

        # Retransmissions and Timeouts
        print_section_header "Retransmissions and Timeouts"
        netstat -s | awk '/retransmits|TCPAbortOnTimeout/ {printf "%-30s %s\n", $1, $NF}'

        # Problematic Connections with Retransmissions
        print_section_header "Problematic Connections (with Retransmissions)"
        printf "%-8s %-10s %-20s %-20s %-8s %-8s\n" State Retrans Local Remote RTT CWND
        ss -t -i | awk '$5 > 0 {printf "%-8s %-10s %-20s %-20s %-8s %-8s\n", $1, $5, $4, $3, $6, $7}'

        # TCP Congestion Indicators
        print_section_header "TCP Congestion Indicators"
        nstat -az TcpExt | awk '/TCPSynRetrans|TCPOutRsts|TCPRenoRecovery/ {printf "%-20s %s\n", $1, $NF}'

        # Recent Network Errors from Logs
        print_section_header "Recent Network Errors from Logs"
        grep -i -E "network|connection|timeout" /var/log/syslog /var/log/kern.log | tail -n 10

        # Network Interface Errors
        print_section_header "Network Interface Errors"
        for interface in $(ls /sys/class/net/ | grep -v lo); do
            echo "Interface: $interface"
            ifconfig $interface | grep -E 'RX errors|TX errors|collisions|dropped'
            echo ""
        done

        # Ping Latency Check
        print_section_header "Ping Latency"
        hosts=("8.8.8.8" "1.1.1.1" "google.com")
        for host in "${hosts[@]}"; do
            echo "Pinging $host..."
            ping -c 4 $host | grep 'rtt'
            echo ""
        done

        # DNS Resolution Test
        print_section_header "DNS Resolution Test"
        dns_servers=("8.8.8.8" "1.1.1.1")
        test_domain="example.com"
        for dns in "${dns_servers[@]}"; do
            echo "Testing DNS server: $dns"
            nslookup $test_domain $dns
            echo ""
        done

        # Firewall Status and Rules
        print_section_header "Firewall Status and Rules"
        if [ -x "$(command -v ufw)" ]; then
            sudo ufw status verbose
        elif [ -x "$(command -v iptables)" ]; then
            sudo iptables -L -v -n
        else
            echo "No firewall tools found (ufw/iptables)."
        fi

        # TCP/IP Configuration Check
        print_section_header "TCP/IP Configuration"
        echo "MTU Sizes:"
        ip link | grep mtu
        echo ""

        echo ""
        echo "################################################################################"
        echo "# Network Health Report Completed"
        echo "################################################################################"
    fi
}

# Run the script on remote servers if -r is specified
if [ "$remote_run" = true ]; then
    if [ ! -f "$workers_conf" ]; then
        echo "Error: workers.conf file not found at $workers_conf"
        exit 1
    fi
    while IFS= read -r server; do
        echo "Running network health check on $server"
        run_script "$server"
    done < "$workers_conf"
else
    run_script
fi