#!/bin/sh

# This script will launch the psu patching script for all QA
# and UAT PAYOR databases listed below.

# Sample Script Executions

#   install_psu_patch.sh 12.1.0.2.200414
#   nohup install_psu_patch.sh 12.1.0.2.200414 &

# Confirm Script OutPut Directory Exists
if [ ! -d /home/oracle/tls/patches/logs ] ; then
   mkdir -p /home/oracle/tls/patches/logs
   chmod 700 /home/oracle/tls/patches/logs
fi

# Change Directory
cd /home/oracle/tls/patches/logs

# Check For Input PSU Directory Name
if [ ${#} -ne 1 ]
then
 echo
 echo "Input PSU Patch Dir Not Passed - Script Aborting"
 exit 1
fi

# Get Input PSU Patch Directory
PSU="$1"

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=HEPYQA
. oraenv > /dev/null 2>&1

# Confirm PSU Patch Directory Exists
if [ ! -d ${ORACLE_BASE}/product/${PSU} ] ; then
   echo "PSU Patch Directory ${ORACLE_BASE}/product/${PSU} Not Found - Script Aborting"
   exit 1
fi

# Set Current Date
DATEV="`date +%Y%m%d`"

# Set Current Date/Time
DATETIME="`date +%Y%m%d_%H%M%S`"

# Set Master Log File Name
LOGFILE=apply_psu_${PSU}_to_qa_databases_${DATETIME}.log

# Set To PSU Script Log OutPut Directory
LOGDIR=/orahome/u01/app/oracle/local/logs

# Note Script Start Time
echo "Starting Script $0 Using Input PSU ${PSU} at "`date` > ${LOGFILE}
echo >> ${LOGFILE}

# Patch Databases
for db in "HEPYQA" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Upper Case Database Name
typeset -u db

# Launch PSU Patching Script
case ${db} in
     "HEPYQA")
     ORACLE_SID=$db
     ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HECVQA")
     host=xhecvdbw21q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     ssh -q ${host} ${SCRIPTS}/patch_db.sh ${PSU} ${db} &
     ;;
     *)
     echo
     echo "${db} Not A Recognized PAYOR QA or UAT DataBase - Patching Skipped For This DataBase"
     echo
     continue
     ;;      
esac

done

# Wait For All PSU Patching To Complete
echo
echo "Waiting For All PSU Patching Scripts To Complete"
echo
wait

# Get Database PSU Patching Logs
for db in "HEPYQA" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HEPYQA_STBY" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Upper Case Database Name
typeset -u db

# Get PSU Log File
case ${db} in
     "HEPYQA")
     FN=`ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     cp -p ${FN} .
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HEPYQA_STBY")
     stdbydb=HEPYQA
     host=xhepydbm21q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_standby_db_${stdbydb}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HECVQA")
     host=xhecvdbw21q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     FN=`ssh -q ${host} ls -1tr ${LOGDIR}/patch_db_${db}_${DATEV}*.out |tail -1`
     scp -pq ${host}:${FN} .
     ;;
     *)
     continue
     ;;      
esac

# Append To Master Log
if [ -f `basename ${FN}` ] ; then
   echo >> ${LOGFILE}
   echo "***************************** DataBase ${db} *****************************" >> ${LOGFILE}
   cat `basename ${FN}` >> ${LOGFILE}
   echo >> ${LOGFILE}
else
   echo >> ${LOGFILE}
   echo "***************************** DataBase ${db} *****************************" >> ${LOGFILE}
   echo "PSU Log File Not Found For DataBase ${db}" >> ${LOGFILE}
   echo >> ${LOGFILE}
fi

done

# Note Script End Time
echo >> ${LOGFILE}
echo "Ending Script $0 at "`date` >> ${LOGFILE}
echo >> ${LOGFILE}

# Change File Permissions
chmod 600 *.log *.out

