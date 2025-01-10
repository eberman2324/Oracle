#!/bin/ksh

# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"




# Change Directory
cd ${SCRDIR}

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database Name"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName

# Set DayTime
MMDDYYYY=`date +"%m%d%Y"`

# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1



# Check and kill sessions
sqlplus > /dev/null <<EOF
/ as sysdba
whenever sqlerror exit failure;
@kill_hanganalyzer_session.sql ${MMDDYYYY}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Killing hang analyzer session "
   exit 1
else
   echo "Killing hang analyzer session Completed"
    exit 0
fi

