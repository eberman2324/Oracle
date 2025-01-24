#!/bin/ksh

# Set To Script Directory
SCRDIR="/home/oracle/eb/redef"

# Change Directory
cd ${SCRDIR}

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName

# Set Email Distribution
MAILIDS=bermane@aetna.com

# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

# Move table
sqlplus -s <<EOF
/ as sysdba
@${SCRDIR}/run_redef.sql
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered Redef Table"
   mailx -s "Error Encountered Redef Table" ${MAILIDS} < run_redef.out
   exit 1
else
   mailx -s "Redef Table Completed" ${MAILIDS} < run_redef.out
fi




# Change Permissions
chmod 600 run_redef.out

echo Done