#!/bin/bash

##############################
##### 1. Enable KILL JOB #####
##### 2. DROP GRP        #####
##############################

# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts



# Change To Script Directory
cd ${SCRDIR}


# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Define Mail Distribution and variables
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`
MAILIDS1=`paste -s ${SCRDIR}/dba_mail_list_1`
LOGFILE=${SCRDIR}/PY_DROP_GRP.log
export GRP_NAME=b4_app_upgrade


log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Set To Input Database Name
DBName=$1
typeset -u DBName


##########################################################################################################

#ps -ef| grep pmon > pmon_drp.out
ps -ef | grep pmon | grep -v grep > pmon_drp.out
ps -ef| grep ${DBName} pmon_drp.out |awk '{ print $8 }' | tail -c 10 > instname_drp.out
DBName=`cat instname_drp.out`



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

##########################################################################################################


# Remove From Previous Run
if [ -f ${SCRDIR}/ps_${DBName}_py_drop_grp_job.out ] ; then
   rm ${SCRDIR}/ps_${DBName}_py_drop_grp_job.out
fi

# Define Work Variables
SCRPTCNT=0

# Is Script Already Running ( this script designed to be in cron. When running from cron each execution gets 2 processes.
ps -ef > ${SCRDIR}/ps_${DBName}_py_drop_grp_job.out
wait
SCRPTCNT=`grep -i "PY_DROP_GRP.sh" ps_${DBName}_py_drop_grp_job.out |grep -i ${DBName} |grep -v grep |wc -l`
echo $SCRPTCNT

if [ ${SCRPTCNT} -gt 2 ]; then
   echo "PY_DROP_GRP Job - Overlap. Job Already Running for Database ${DBName}"
   mailx -s "PY_DROP_GRP script Overlap! " ${MAILIDS1} < ps_${DBName}_py_drop_grp_job.out
   exit 0
fi



# Remove From Previous Run
if [ -f ${SCRDIR}/PY_DROP_GRP.log ] ; then
   rm ${SCRDIR}/PY_DROP_GRP.log
fi

# Remove From Previous Run
if [ -f ${SCRDIR}/py_drop_grp_flag.out ] ; then
   rm ${SCRDIR}/py_drop_grp_flag.out
fi

# Check For Restore Point
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool py_drop_grp_flag.out
select trim(count(*))
FROM AEDBA.HRP_UPGRADE_JOB_FLAG 
WHERE JOB_ID = 2 AND IS_JOB_ACTIVE = 'Y';
EOF


# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Checking for PY_DROP_GRP JOB Flag in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Checking for PY_DROP_GRP JOB Flag" ${MAILIDS1} < ${LOGFILE}
   exit 1
else
   log_console "Success Checking for PY_DROP_GRP JOB Flag in Database " ${DBName}
   log_console " "
fi

CNT=`cat py_drop_grp_flag.out`
if [ ${CNT} -gt 0 ] ; then
   log_console "Flag for PY_DROP_GRP JOB is Y for Database " ${DBName}
   log_console " "
   log_console "Setting Flag for PY_DROP_GRP JOB back to N for Database" ${DBName}
   log_console " "
# Update FLAG
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
UPDATE AEDBA.HRP_UPGRADE_JOB_FLAG SET IS_JOB_ACTIVE = 'N' WHERE JOB_ID = 2;
commit;
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Updading PY_DROP_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Updading PY_DROP_GRP JOB Flag" ${MAILIDS} < ${LOGFILE} 
   exit 1
else
   log_console "Success Updating PY_DROP_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
fi

echo "Starting enabling of KILL JOB"
log_console "Starting enabling of KILL JOB" 
log_console " " 
nohup ${SCRDIR}/enable_KILL_JOB.sh >> $LOGFILE 2>&1
retn_code_1=$?


## Success or Failure ? ##
if [ $retn_code_1 -eq 0 ]
then
  echo "Enable of KILL JOB completed with Success"
  log_console "Enable of KILL JOB completed with Success"   
  log_console " "
  mailx -s "PY Post HRP Steps completed with Success" ${MAILIDS} < ${LOGFILE}
  exit 0
else
  echo "Error enabling of KILL JOB!!!"
  log_console "Error enabling of KILL JOB!!!"
  log_console " "
  mailx -s "Error enabling of KILL JOB!!!" ${MAILIDS} < ${LOGFILE}
  exit 1
fi

#echo "Starting PY GRP drop"
#log_console "Starting PY GRP drop"
#log_console " " 
#nohup ${SCR}/drop_guaranteed_restore_point.sh ${DBName} ${GRP_NAME} >> $LOGFILE 2>&1
#retn_code=$?


 
## Success or Failure ? ##
#if [ $retn_code -eq 0 ]
#then
#  echo "PY GRP drop completed with Success"
#  log_console " PY GRP drop completed with Success"
#  log_console " "
#   mailx -s " PY GRP drop completed with Success" ${MAILIDS} < ${LOGFILE}
#  exit 0
#else
#  echo "PY GRP drop completed with Errors!!!"
#  log_console "PY GRP drop completed with Errors!!!"
#  log_console " "
#  mailx -s "PY GRP drop completed with Errors!!!" ${MAILIDS} < ${LOGFILE}
#  exit 1
#fi

else
   log_console "FLAG for PY_CREATE_GRP JOB is N for Database " ${DBName}
   log_console " "
   log_console "Going back to sleep will wake up in 5 min to check again."
   log_console " "
   exit 0
fi
