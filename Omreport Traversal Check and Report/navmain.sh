#!/bin/bash
# Author: SH3LL
# Github: https://github.com/SH3LLco

# sets date variable
date=$(date +%Y-%m-%d)

# define working directory where scripts are located
FILE_DIR="/path/to/scripts"

# define local host report destination
REPORT_DIR="/path/to/reports"

# define safe working directory
WORK_DIR="/tmp/healthcheck"

# define the script to be copied and executed
SCRIPT_NAME="healthcheck.sh"

# define the report name
REPORT_NAME="report.csv"

# define the combined report name
COMBINED_REPORT="${date}.csv"

# define the ssh username
USER="user" # assumes SSH key-based authentication set up for each host in the list

# define SSH KEY
SSH_KEY="/user/.ssh/key"

# Define host list file
HOST_LIST="${FILE_DIR}/hosts.txt"

# setup local working environment
if [ ! -d "$WORK_DIR" ]; then
    mkdir -p "$WORK_DIR"
    echo "$WORK_DIR created."
fi
cd "$WORK_DIR"

# Check if hosts file exists
if [ ! -f "$HOST_LIST" ]; then
    echo "Host list file $HOST_LIST does not exist. Exiting."
    exit 1
fi

# Check if report directory exists
if [ ! -d "$REPORT_DIR" ]; then
    mkdir -p "$REPORT_DIR"
    echo "$REPORT_DIR created."
fi

# Check if local IP is in host list and run locally if present
LOCAL_IP=$(hostname -I | awk '{print $1}')  # Get local IP, adjust if your IP configuration is different
if grep -q "$LOCAL_IP" "$HOST_LIST"; then
    echo "Running script locally."
    cd "${FILE_DIR}/"
    chmod +x "$SCRIPT_NAME"
    ./"$SCRIPT_NAME"
    mv "$REPORT_NAME" "${REPORT_DIR}/$REPORT_NAME.$LOCAL_IP"
else
    echo "Local IP $LOCAL_IP is not in the list. Proceeding with remote hosts."
fi

# read hosts into array
mapfile -t hosts < "$HOST_LIST"

# Loop through the host list
for host in "${hosts[@]}"; do
    
    host=$(echo "$host" | xargs)

    # Check if the current line is the local IP. If it is, skip this iteration.
    if [ "$host" == "$LOCAL_IP" ]; then
        echo "Skipping local host ($host)."
        continue
    fi

    echo "Processing host: $host"

    # Perform SSH authentication test
    if ! ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" "exit"; then
        echo "SSH authentication failed for $host. Skipping..."
        continue
    fi

    echo "SSH authentication successful for $host."

    # SSH into the host, create the work directory
    ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" << EOF
if [ ! -d "$WORK_DIR" ]; then
    mkdir -p "$WORK_DIR"
    echo "$WORK_DIR created."
fi
EOF

    # Copy the script to the remote host and execute it
    if ! scp -i "${SSH_KEY}" -o ConnectTimeout=5 "${FILE_DIR}/${SCRIPT_NAME}" "${USER}@${host}:${WORK_DIR}/"; then
        echo "Failed to copy script to $host. Skipping..."
        continue
    fi

    ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" << EOF
cd "$WORK_DIR/"
chmod +x "$SCRIPT_NAME"
./"$SCRIPT_NAME"
EOF

    # Move the report file to the local host
    if ! scp -i "${SSH_KEY}" -o ConnectTimeout=5 "${USER}@${host}:${WORK_DIR}/${REPORT_NAME}" "${REPORT_DIR}/${REPORT_NAME}.${host}"; then
        echo "Failed to retrieve report from $host. Skipping..."
        continue
    fi
    
    # Remove the report file and script from the remote host
    ssh -i "${SSH_KEY}" -T -o BatchMode=yes -o ConnectTimeout=5 "${USER}@${host}" << EOF
cd "$WORK_DIR/"
rm "${SCRIPT_NAME}"
rm "${REPORT_NAME}"
EOF

done

# Combine all the report files into one
echo "Combining all reports..."
{
    cd "${REPORT_DIR}/"
    echo "$date"
    for report_file in "$REPORT_NAME".*; do
        cat "$report_file"
        echo -e "\n\n\n\n"
    done
} > "${REPORT_DIR}/${COMBINED_REPORT}"

cd "${REPORT_DIR}/"
rm -f ./report.csv.*

echo "All tasks completed. Combined report is saved as $COMBINED_REPORT."
