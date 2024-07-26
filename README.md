# Omreport Traversal Check and Report
- Use navmain.sh to execute traversal
- Use healthcheck.sh to execute a single report

### Instructions
- create a directory to house these scripts
- in the directory, create a hosts.txt file with all IPs of hosts you want to check, one per line
- in navmain.sh, customize your script variables
- chmod +x navmain.sh
- chmod +x healthcheck.sh
- ./navmain.sh

#### Checks the following
- omreport chassis
- omreport storage enclosures
- omreport storage batteries
- omreport controllers
- omreport controller vdisks
- omreport controller pdisks


# RHEL Security Updates
- use security-update.sh to run security updates on all hosts in hosts.txt, one per line.

### Instructions
- create a directory to house these scripts
- in the directory, create a hosts.txt file with all IPs of hosts you want to check, one per line
- in security-update.sh, customize your script variables
- chmod +x security-update.sh
- ./security-update.sh

#### Does the following
- yum update --security -y
- logs the updates/errors to a log file
- formats the log for easy review
