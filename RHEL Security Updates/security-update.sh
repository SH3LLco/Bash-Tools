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

LOCAL_IP=$(hostname -I | awk '{print $1}')  # Get local IP, adjust if your IP configuration is different
if grep -q "$LOCAL_IP" "$HOST_LIST"; then
    echo "Running script locally."
    echo -e "\n\n==============================" >> "$LOG_FILE"
    echo "Processing host: $LOCAL_IP" >> "$LOG_FILE"
    echo "==============================" >> "$LOG_FILE"
    echo "Starting security update on $LOCAL_IP..."
    yum update --security -y >> "$LOG_FILE"
    echo "Security update completed on $LOCAL_IP..."
else
    echo "Local IP $LOCAL_IP is not in the list. Proceeding with remote hosts."
fi

# Read hosts into an array
mapfile -t hosts < "$HOST_LIST"

# Loop through the host array
for host in "${hosts[@]}"; do
    host=$(echo "$host" | xargs)

    if [ "$host" == "$LOCAL_IP" ]; then
        echo "Skipping local host ($host)."
        continue
    fi

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
