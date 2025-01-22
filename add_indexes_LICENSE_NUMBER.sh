#!/bin/ksh

# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/refresh/HEPYMASK"

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
#MAILIDS=bermane@aetna.com
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/refresh/HEPYMASK/dba_mail_list`

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
@${SCRDIR}/add_indexes_LICENSE_NUMBER.sql
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered adding indexes"
   mailx -s "Error Encountered adding indexes" ${MAILIDS} < add_indexes_LICENSE_NUMBER.out
   exit 1
else
   mailx -s "adding indexes Completed" ${MAILIDS} < add_indexes_LICENSE_NUMBER.out
fi




# Change Permissions
chmod 600 add_indexes_LICENSE_NUMBER.out

echo Done
