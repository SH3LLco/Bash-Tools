#!/bin/bash

# DO NOT USE THIS, this is just for some additional setup i had to do and is a broken skeleton because i used it multiple times for different purposes. 


# Specify the path to the public key you want to transfer
local_file="/user/path/file.pub"

# Specify the remote directory where the file should be transferred
remote_directory="/user/.ssh/"

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
    commands go here, one per line. Each ssh setup is different so i left this empty. 
    my setup was unique, but you likely want to cat the public key and append >> to authorize_keys
    or if ssh isnt setup, this is where your commands go to set everything up per host. 
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
