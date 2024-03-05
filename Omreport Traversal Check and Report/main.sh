#!/bin/bash
while IFS= read -r hostname; do
    # Your logic for each hostname goes here
    echo "Processing hostname: $hostname"
    # Example: Run a command on the remote host
    ssh "$hostname" "echo Hello from $hostname"
done < "$hostfile"

for i in $hostlist; do
    if $hostname == $i; then
        scriptfunction
    else
        sshfunction $i
        scriptfunction
        scp function
        cleanupfunction
