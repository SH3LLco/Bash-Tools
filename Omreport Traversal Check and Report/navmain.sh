#!/bin/bash
# Author: SH3LL
# Github: https://github.com/SH3LLco

# sets date variable
date=$(date +%Y-%m-%d)

# define working directory where scripts are located
FILE_DIR="/path/to/script/folder"

# define local host operation directory
OP_DIR="/local/path/where/operating"

# define safe working directory
WORK_DIR="/tmp/healthcheck"

# define the script to be copied and executed
SCRIPT_NAME="healthcheck.sh"

# define the report name
REPORT_NAME="report.csv"

# define the combined report name
COMBINED_REPORT="${date}_report.csv"

# define the ssh username
USER="username" # assumes SSH key-based authentication set up for each host in the list

# Define host list file
HOST_LIST="hosts.txt"

# setup local working environment
if [ ! -d "$WORK_DIR" ]; then
    mkdir -p "$WORK_DIR"
    echo "$WORK_DIR created."
fi
cd "$WORK_DIR"


# Check if local IP is in host list and run locally if present
LOCAL_IP=$(hostname -I | awk '{print $1}')  # Get local IP, adjust if your IP configuration is different
if grep -q "$LOCAL_IP" "$HOST_LIST"; then
    echo "Running script locally."
    cp "${FILE_DIR}/${SCRIPT_NAME}" .
    chmod +x "$SCRIPT_NAME"
    ./"$SCRIPT_NAME"
    mv "$REPORT_NAME" "$REPORT_NAME.$LOCAL_IP"
    cd -
else
    echo "Local IP $LOCAL_IP is not in the list. Proceeding with remote hosts."
fi

# Loop through the host list
while IFS= read -r host
do

    # Check if the current line is the local IP. If it is, skip this iteration.
    if [ "$host" == "$LOCAL_IP" ]; then
        echo "Skipping local host ($host)."
        continue
    fi

    echo "Processing host: $host"

    # SSH into the host, create the work directory
    ssh -o BatchMode=yes "$host" << EOF
    if [ ! -d "$WORK_DIR" ]; then
        mkdir -p "$WORK_DIR"
        echo "$WORK_DIR created."
    fi
EOF

    # Copy the script to the remote host and execute it
    scp ${FILE_DIR}/${SCRIPT_NAME} ${USER}@${host}:${WORK_DIR}/
    ssh -o BatchMode=yes "$host" << EOF
    cd "$WORK_DIR/"
    chmod +x "$SCRIPT_NAME"
    ./"$SCRIPT_NAME"
EOF

    # Move the report file to the local host
    scp ${USER}@${host}:${WORK_DIR}/${REPORT_NAME} ${OP_DIR}/${REPORT_NAME}.${host}
    
    # Remove the report file from the remote host
    ssh -o BatchMode=yes "$host" << EOF
    cd "$WORK_DIR/"
    rm "${SCRIPT_NAME}"
EOF

done < "$HOST_LIST"

# Combine all the report files into one
echo "Combining all reports..."
{
    echo "$date"
    for report_file in "$REPORT_NAME".*; do
        cat "$report_file"
    done
} > "$COMBINED_REPORT"

echo "All tasks completed. Combined report is saved as $COMBINED_REPORT."

echo "All tasks completed. Combined report is saved as $COMBINED_REPORT."
