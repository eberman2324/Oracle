#!/bin/bash


###################################################################################################
###### 1. KILL RUNNING STATS JOBS               			 		     ######
###### 2. KILL ANY OUTSTANDING PROD CONNECTIONS                           	             ######
###### 3. DISABLE KILL JOB, STATS JOBS and HANG ANALYZER JOB (enable crontab_during_grp.lst) ######
###################################################################################################


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
LOGFILE=${SCRDIR}/PY_CREATE_GRP.log
export GRP_NAME=b4_app_upgrade


log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Set To Input Database Name
DBName=$1
typeset -u DBName

##########################################################################################################

#ps -ef| grep pmon > pmon_crt.out
ps -ef | grep pmon | grep -v grep > pmon_crt.out
ps -ef| grep ${DBName} pmon_crt.out |awk '{ print $8 }' | tail -c 10 > instname_crt.out
DBName=`cat instname_crt.out`

# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1
##########################################################################################################


# Remove From Previous Run
if [ -f ${SCRDIR}/ps_${DBName}_py_create_grp_job.out ] ; then
   rm ${SCRDIR}/ps_${DBName}_py_create_grp_job.out
fi



# Define Work Variables
SCRPTCNT=0

# Is Script Already Running ( this script designed to be in cron. When running from cron each execution gets 2 processes.
ps -ef > ${SCRDIR}/ps_${DBName}_py_create_grp_job.out
wait
SCRPTCNT=`grep -i "PY_CREATE_GRP.sh" ps_${DBName}_py_create_grp_job.out |grep -i ${DBName} |grep -v grep |wc -l`
echo $SCRPTCNT

if [ ${SCRPTCNT} -gt 2 ]; then
   echo "PY_CREATE_GRP Job - Overlap. Job Already Running for Database ${DBName}"
   mailx -s "PY_CREATE_GRP script Overlap! " ${MAILIDS1} < ps_${DBName}_py_create_grp_job.out
   exit 0
fi





# Remove From Previous Run
if [ -f ${SCRDIR}/PY_CREATE_GRP.log ] ; then
   rm ${SCRDIR}/PY_CREATE_GRP.log
fi

# Remove From Previous Run
if [ -f ${SCRDIR}/py_create_grp_flag.out ] ; then
   rm ${SCRDIR}/py_create_grp_flag.out
fi

# Check For Restore Point
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool py_create_grp_flag.out
select trim(count(*))
FROM AEDBA.HRP_UPGRADE_JOB_FLAG 
WHERE JOB_ID = 1 AND IS_JOB_ACTIVE = 'Y';
EOF


# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Checking for PY_CREATE_GRP JOB Flag in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Checking for PY_CREATE_GRP JOB Flag" ${MAILIDS1} < ${LOGFILE}
   exit 1
else
   log_console "Success Checking for PY_CREATE_GRP JOB Flag in Database " ${DBName}
   log_console " "
fi

CNT=`cat py_create_grp_flag.out`
if [ ${CNT} -gt 0 ] ; then
   log_console "Flag for PY_CREATE_GRP JOB is Y for Database " ${DBName}
   log_console " "
   log_console "Setting Flag for PY_CREATE_GRP JOB back to N for Database" ${DBName}
   log_console " "
# Update FLAG
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
UPDATE AEDBA.HRP_UPGRADE_JOB_FLAG SET IS_JOB_ACTIVE = 'N' WHERE JOB_ID = 1;
commit;
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Updading PY_CREATE_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Updading PY_CREATE_GRP JOB Flag" ${MAILIDS} < ${LOGFILE} 
   exit 1
else
   log_console "Success Updating PY_CREATE_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
fi





echo "Starting checking and killing any running stats jobs"
log_console "Starting checking and killing any running stats jobs"
log_console " "
nohup ${SCRDIR}/kill_running_stats_jobs.sh ${DBName} >> $LOGFILE 2>&1
retn_code_2=$?


## Success or Failure ? ##
if [ $retn_code_2 -eq 0 ]
then
  echo "Kiling Running Stats Jobs completed with Success"
  log_console  "Kiling Running Stats Jobs completed with Success" 
  log_console " " 
else
  echo "Error Kiling Running Stats Jobs!!!"
  log_console "Error Kiling Running Stats Jobs!!!"
  log_console " "
  mailx -s "Error Kiling Running Stats Jobs!!!" ${MAILIDS} < ${LOGFILE}
  exit 1
fi


echo "Starting checking and killing any PROD outstanding connections"
log_console "Starting checking and killing any PROD outstanding connections"
log_console " " 
nohup ${SCRDIR}/kill_prod_connections.sh ${DBName} >> $LOGFILE 2>&1
retn_code_3=$?


## Success or Failure ? ##
if [ $retn_code_3 -eq 0 ]
then
  echo "Kiling PROD connections completed with Success"
  log_console  "Kiling PROD connections completed with Success"  
  log_console " "
else
  echo "Error Kiling PROD connections!!!"
  log_console "Error KilingPROD connections!!!"
  log_console " "
  mailx -s "Error Kiling PROD connections!!!" ${MAILIDS} < ${LOGFILE}
  exit 1
fi


echo "Starting checking and killing hang analyzer job session"
log_console "Starting checking and killing hang analyzer job session"
log_console " " 
nohup ${SCRDIR}/kill_hanganalyzer_session.sh ${DBName} >> $LOGFILE 2>&1
retn_code_4=$?


## Success or Failure ? ##
if [ $retn_code_4 -eq 0 ]
then
  echo "Kiling hang analyzer job session completed with Success"
  log_console  "Kiling hang analyzer job session completed with Success"  
  log_console " "
else
  echo "Error killing hang analyzer job session!!!"
  log_console "Error killing hang analyzer job session!!!"
  log_console " "
  mailx -s "Error killing hang analyzer job session!!!" ${MAILIDS} < ${LOGFILE}
  exit 1
fi



# For RACONE use Jenkins GRP automation actions !!!
#echo "Starting PY GRP creation"
#log_console "Starting PY GRP creation"
#log_console " "
#nohup ${SCR}/create_guaranteed_restore_point.sh ${DBName} ${GRP_NAME} >> $LOGFILE 2>&1
#retn_code=$?


 
## Success or Failure ? ##
#if [ $retn_code -eq 0 ]
#then
#  echo "PY GRP creation completed with Success"
#  log_console " PY GRP creation completed with Success"
#  log_console " "
#  #mailx -s " PY GRP creation completed with Success" ${MAILIDS} < ${LOGFILE}
#  #exit 0
#else
#  echo "PY GRP creation completed with Errors!!!"
#  log_console "PY GRP creation completed with Errors!!!"
#  log_console " "
#  mailx -s "PY GRP creation Step completed with Errors!!!" ${MAILIDS} < ${LOGFILE}
#  exit 1
#fi


echo "Starting disabling Kill Job, stats jobs and hang_analyze job by removing them from crontab schedule"
log_console "Starting disabling KILL JOB, STATS JOBS AND HANG ANALYZE JOB"
log_console " "
nohup ${SCRDIR}/disable_KILL_JOB.sh >> $LOGFILE 2>&1
retn_code_1=$?


## Success or Failure ? ##
if [ $retn_code_1 -eq 0 ]
then
  echo "Disable of KILL JOB, STATS JOBS AND HANG ANALYZE JOBS completed with Success"
  log_console  "Disable of KILL JOB, STATS JOBS AND HANG ANALYZE JOBS completed with Success"  
  log_console " "
  mailx -s "PY Pre HRP Upgrade steps completed with Success" ${MAILIDS} < ${LOGFILE}
  exit 0
else
  echo "Error disabling KILL JOB, STATS JOBS AND HANG ANALYZE JOBS!!!"
  log_console "Error disabling KILL JOB, STATS JOBS AND HANG ANALYZE JOBS!!!"
  log_console " "
  mailx -s "Error disabling KILL JOB, STATS JOBS AND HANG ANALYZE JOBS!!!" ${MAILIDS} < ${LOGFILE}
  exit 1
fi




else
   log_console "FLAG for PY_CREATE_GRP JOB is N for Database " ${DBName}
   log_console " "
   log_console "Going back to sleep will wake up in 5 min to check again."
   log_console " " 
   exit 0
fi

