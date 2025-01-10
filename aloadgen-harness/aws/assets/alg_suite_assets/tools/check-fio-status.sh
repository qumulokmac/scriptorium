i#!/bin/bash

workers_file=~/workers.conf
temp_file=$(mktemp)

if [[ ! -f "$workers_file" ]]; then
    echo -e "\e[31mError: workers.conf file not found!\e[0m"
    exit 1
fi

grand_total_parents=0
grand_total_children=0

echo ""
echo "---------------------------------------"

while IFS= read -r ip; do
    echo -e "\e[34m${ip}:\e[0m"
    
    # Run the SSH command and capture the output
    ssh_output=$(ssh "$ip" bash <<'EOF'
        num_parents=$(ps -ef | grep nohup | grep -v grep | wc -l)
        total_children=0
        
        if (( num_parents > 0 )); then
            echo -e "\e[32m  FIO parent processes running: $num_parents\e[0m"
            for pid in $(ps -ef | grep nohup | grep -v grep | awk '{print $2}'); do
                num_children=$(pstree -p $pid | grep -v $pid | wc -l)
                total_children=$((total_children + num_children))
                echo -e "    \e[33m$pid --> $num_children children\e[0m"
            done
            echo -e "\e[36m    Total fio procs for $ip: $total_children\e[0m"
        else
            echo -e "\e[31mNo parent FIO processes running.\e[0m"
        fi
        echo "$num_parents $total_children"
EOF
    )

    # Display the output, excluding the last line (summary values)
    echo "$ssh_output" | head -n -1

    # Extract totals from the last line of the output
    summary_line=$(echo "$ssh_output" | tail -n 1)
    parents=$(echo "$summary_line" | awk '{print $1}')
    children=$(echo "$summary_line" | awk '{print $2}')
    
    # Update the grand totals
    grand_total_parents=$((grand_total_parents + parents))
    grand_total_children=$((grand_total_children + children))

    echo "---------------------------------------"
    echo ""
done < "$workers_file"

# Print the grand summary
echo -e "\e[35mGrand Summary:\e[0m"
echo -e "\e[32m  Total FIO parent processes across all servers: $grand_total_parents\e[0m"
echo -e "\e[36m  Total FIO child processes across all servers: $grand_total_children\e[0m"
