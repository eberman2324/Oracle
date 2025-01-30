#!/usr/bin/ksh

# Check DataBase Connection For Input DataBase

# Check for Input DataBase and DBAID and DBA Password
if [ ${#} -ne 3 ]
then
 echo
 echo "Input DataBase and DBA ID and DBA Password Not Passed - Script Aborting"
 exit 0
fi

# Set DataBase Name
DBName=$1

# Set To DBA ID
DBAID=$2

# Set To DBA Password
DBAPASS=$3

# Change Directory
cd /home/oracle/tls/patches

# Set Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export PATH
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Connect To DataBase
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect ${DBAID}/${DBAPASS}@${DBName}
 select instance_name,startup_time from v\$instance;
EOF

exit $?

