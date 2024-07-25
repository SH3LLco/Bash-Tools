#!/bin/bash

# Specify the path to the local file you want to transfer
local_file="/root/abilenetech/healthcheck/healthcheck.sh"

# Specify the remote directory where the file should be transferred
remote_directory="/root/abilenetech/scripts/"

# Define the path to your private SSH key (optional)
ssh_key="full/path/to/key"

# Define the username to use for SSH
username="username"

# Path to the file containing the list of hosts
host_list="hosts.txt"

while IFS= read -r host
do

    echo "Processing host: $host"

    # SSH into the host, create the directory, copy and execute the script
    ssh -i "$ssh_key" -o BatchMode=yes "$host" << EOF
    commands go here, one per line
EOF

done < "$host_list"

# Loop through each host in the list
while read -r host; do
    echo "Transferring file to $host..."

    # Execute the SCP command
    scp -i "$ssh_key" "$local_file" "${username}@${host}:${remote_directory}"

    # Check if SCP was successful
    if [ $? -eq 0 ]; then
        echo "File transferred successfully to $host."
    else
        echo "Failed to transfer file to $host."
    fi
done < "$host_list"

echo "All done."
