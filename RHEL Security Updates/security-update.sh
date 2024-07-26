#!/bin/bash
# Author: SH3LL
# Github: https://github.com/SH3LLco

DATE=$(date +%Y-%m-%d)

# Define the SSH username and key
USER="user"
SSH_KEY="/user/path/key"

# Define host list file
HOST_LIST="path/to/hosts.txt"

# Define log file
LOG_FILE="path/to/${DATE}.log"

# Initialize log file
echo "Security Update Log - ${DATE}" > "$LOG_FILE"
echo "==============================" >> "$LOG_FILE"

# Read hosts into an array
mapfile -t hosts < "$HOST_LIST"

# Loop through the host array
for host in "${hosts[@]}"; do
    host=$(echo "$host" | xargs)

    # Add a separator for each host in the log file
    echo -e "\n\n==============================" >> "$LOG_FILE"
    echo "Processing host: $host" >> "$LOG_FILE"
    echo "==============================" >> "$LOG_FILE"

    echo "Processing host: $host"

    # Perform SSH authentication test
    if ! ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" "exit"; then
        echo "SSH authentication failed for $host. Skipping..."
        echo "SSH authentication failed for $host. Skipping..." >> "$LOG_FILE"
        continue
    fi

    echo "SSH authentication successful for $host."
    echo "SSH authentication successful for $host." >> "$LOG_FILE"

    # SSH into the host and perform the security update, capturing the output and errors
    ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" << EOF >> "$LOG_FILE" 2>&1
echo "Starting security update on $host..."
yum update --security -y
echo "Security update completed on $host."
EOF

    echo "Security updates installed on $host."
    echo "Security updates installed on $host." >> "$LOG_FILE"

done

echo "All security updates completed."
echo "All security updates completed." >> "$LOG_FILE"
