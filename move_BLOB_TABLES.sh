#!/bin/ksh

# Set To Script Directory
SCRDIR="/home/oracle/eb/tblmove"

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
@${SCRDIR}/move_BLOB_TABLES.sql
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered Moving Table to BifFile Tbs"
   mailx -s "Error Encountered Moving Table to BifFile Tbs" ${MAILIDS} < move_BLOB_TABLES.out
   exit 1
else
   mailx -s "Moving Table to BifFile Tbs Completed" ${MAILIDS} < move_BLOB_TABLES.out
fi




# Change Permissions
chmod 600 move_BLOB_TABLES.out

echo Done