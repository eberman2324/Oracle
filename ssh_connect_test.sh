#!/bin/sh

# Change Directory
cd /home/oracle/tls/rman

# Set Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export PATH

# Define Script Work File
LOGOUT=ssh_connect_test.out

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

echo "Starting ssh on `hostname -s` at `date` "
echo

# SSH To UAT Server
ssh -n xhepydbw1s ${HOME}/tls/rman/ssh_connection_test.sh

echo
echo "Ending ssh on `hostname -s` at `date` "
echo

# Set Permissions
chmod 600 ${LOGOUT}

