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
cMAILIDS=`paste -s ${SCRDIR}/cust_mail_list`
dMAILIDS=`paste -s /oradb/app/oracle/local/scripts/refresh/HEPYMASK/dba_mail_list`

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
@${SCRDIR}/get_Tbl_List.sql
EOF

# Set Script OutPut File
FN=tables.html

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered creating table list"
   mailx -s "Error Encountered creating table list" ${dMAILIDS} < tables.html
   exit 1
else
   #mailx -s "creating table list Completed" ${MAILIDS} < tables.html
   mailx -a ${FN} -s "Tables List - HEPYMASK" ${cMAILIDS} < /dev/null 
fi






# Change Permissions
chmod 600 tables.html

echo Done