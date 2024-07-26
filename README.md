# Bash-Tools
## Omreport Traversal Check and Report
- Use navmain.sh to execute traversal
- Use healthcheck.sh to execute a single report

## Instructions
- create a directory to house these scripts
- in the directory, create a hosts.txt file with all IPs of hosts you want to check, one per line
- in navmain.sh, customize your script variables
- chmod +x navmain.sh
- chmod +x healthcheck.sh
- ./navmain.sh

### Checks the following
- omreport chassis
- omreport storage enclosures
- omreport storage batteries
- omreport controllers
- omreport controller vdisks
- omreport controller pdisks
