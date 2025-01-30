#!/bin/bash

# This script will connect to all QA
# and UAT PAYOR databases listed below.

# Sample Script Execution
#
#   check_databases.sh
#

# Change Directory
cd /home/oracle/tls/patches/logs

clear

echo "Enter DBA ID"
read DBAID

# Confirm DBA ID Entered
if [ -z "${DBAID}" ]; then
   echo
   echo "Must Enter DBA ID"
   exit 1
fi

# Upper Case DBA ID
DBAID=`echo $DBAID |tr "[:lower:]" "[:upper:]"`

echo "Enter DBA Password"
read DBAPass

# Confirm DBA Password Entered
if [ -z "${DBAPass}" ]; then
   echo
   echo "Must Enter DBA Password"
   exit 1
fi

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=HEPYQA
. oraenv > /dev/null 2>&1

# Set Current Date
DATEV="`date +%Y%m%d`"

# Set Current Date/Time
DATETIME="`date +%Y%m%d_%H%M%S`"

# Set Master Log File Name
LOGFILE=check_databases_${DATETIME}.log

# Set To Script Directory
SDIR=/home/oracle/tls/patches

# Redirect standard output and standard error
exec > >(tee ${LOGFILE}) 2>&1

# Note Script Start Time
echo "Starting Script $0 at "`date`
echo

# Check Logs

for db in "HEPYQA" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Upper Case Database Name
typeset -u db

echo
echo "Checking DataBase Connection for DataBase ${db} "
echo

# Launch DataBase Connection Script
case ${db} in
     "HEPYQA")
     ORACLE_SID=$db
     ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HECVQA")
     host=xhecvdbw21q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     ssh -q ${host} ${SDIR}/check_database_connection.sh ${db} ${DBAID} ${DBAPass}
     echo $?
     ;;
     *)
     echo
     echo "${db} Not A Recognized PAYOR QA or UAT DataBase - DataBase Skipped"
     echo
     continue
     ;;      
esac

done

# Note Script End Time
echo
echo "Ending Script $0 at "`date`
echo

# Change File Permissions
chmod 600 *.log

