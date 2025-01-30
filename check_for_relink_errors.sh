#!/bin/bash

# This script will check the relink.log file for all QA
# and UAT PAYOR databases listed below.

# Sample Script Execution
#
#   check_for_relink_errors.sh
#

# Change Directory
cd /home/oracle/tls/patches/logs/relink

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=HEPYQA
. oraenv > /dev/null 2>&1

# Set Current Date
DATEV="`date +%Y%m%d`"

# Set Current Date/Time
DATETIME="`date +%Y%m%d_%H%M%S`"

# Set Master Log File Name
LOGFILE=check_for_relink_errors_${DATETIME}.log

# Set To Script Directory
SDIR=/home/oracle/tls/patches

# Redirect standard output and standard error
exec > >(tee ${LOGFILE}) 2>&1

# Note Script Start Time
echo "Starting Script $0 at "`date`
echo

# Check Logs
for db in "HEPYQA" "HEPYQA_RPT" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Upper Case Database Name
typeset -u db

echo
echo "Checking relink log for DataBase ${db} "
echo >> ${LOGFILE}

# Launch Check Relink Log Script
case ${db} in
     "HEPYQA")
     ORACLE_SID=$db
     ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HEPYQA_RPT")
     host=xhepydbm21q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HECVQA")
     host=xhecvdbw21q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
     echo $?
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     ssh -q ${host} ${SDIR}/check_relink_log.sh
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

