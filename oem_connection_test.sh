#!/bin/sh

# change Directory
cd /home/oracle/tls/rman

# Set Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export PATH

# Set Log File
LOGOUT=oem_connection_test.out

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Set Permissions
chmod 600 ${LOGOUT}

echo "Starting To Sleep at `date` "
echo
sleep 13h
echo
echo "Ending Sleep at `date` "
echo

