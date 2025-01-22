#!/bin/ksh

# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/reorg/table_moves"

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
MAILIDS=`paste -s ${SCRDIR}/cust_mail_list`

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
@${SCRDIR}/table_move_DATA5.sql
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered during Table Moves"
   mailx -s "Error Encountered during Table Movess" ${MAILIDS} < table_move_DATA5.out
   exit 1
else
   mailx -s "Table Moves Completed" ${MAILIDS} < table_move_DATA5.out
fi




# Change Permissions
chmod 600 table_move_DATA5.out

echo Done