#!/bin/bash
# Author: SH3LL
# Github: https://github.com/SH3LLco

# function to get date
function getDate {
    date=$(date +%Y-%m-%d)
    echo "$date"
}

# sets date variable
date=$(getDate)

# define working directory where scripts are located
FILE_DIR="/path/to/script/folder/" # close the directory GOOD=/root/script/folder/ | BAD=/root/script/folder

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
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"


# Check if local IP is in host list and run locally if present
LOCAL_IP=$(hostname -I | awk '{print $1}')  # Get local IP, adjust if your IP configuration is different
if grep -q "$LOCAL_IP" "$HOST_LIST"; then
    echo "Running script locally."
    cp "${FILE_DIR}${SCRIPT_NAME}" .
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

    # SSH into the host, create the directory, copy and execute the script
    ssh -o BatchMode=yes "$host" << EOF
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    scp ${USER}@${LOCAL_IP}:${FILE_DIR}${SCRIPT_NAME} .
    chmod +x "$SCRIPT_NAME"
    ./"$SCRIPT_NAME"
    scp "$REPORT_NAME" ${USER}@${LOCAL_IP}:${WORK_DIR}/$REPORT_NAME.$host
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
