#!/bin/bash

# This script will get the relink.log date for all QA
# and UAT Payor databases listed below.
# Script is used to confirm relink was recently run on servers
# prior to applying PSU patch.
#
# Sample Script Execution
#
#  get_relink_log_date.sh
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

# Set Log File Name
LOGFILE=get_relink_log_file_date_${DATETIME}.log

# Set To Script Directory
SDIR=/home/oracle/tls/patches

# Redirect standard output and standard error
clear
exec > >(tee ${LOGFILE}) 2>&1

# Note Script Start Time
echo "Starting Script $0 at "`date`
echo

# Check Log Dates
for db in "HEPYQA" "HEPYQA_RPT" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Upper Case Database Name
typeset -u db

echo
echo "Get relink log date for DataBase ${db} "
echo

# Launch Get Log Date Script
case ${db} in
     "HEPYQA")
     ORACLE_SID=$db
     ${SDIR}/get_relink_log.sh
     ;;
     "HEPYQA_RPT")
     host=xhepydbm21q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HECVQA")
     host=xhecvdbw21q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     ssh -q ${host} ${SDIR}/get_relink_log.sh
     ;;
     *)
     echo
     echo "${db} Not A Recognized Payor QA or UAT DataBase - DataBase Skipped"
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

