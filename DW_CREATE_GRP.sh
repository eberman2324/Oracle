#!/bin/bash

################################
##### 1. Lock DW Accounts ######
##### 2. CREATE GRP       ######
################################




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
LOGFILE=${SCRDIR}/DW_CREATE_GRP.log
export GRP_NAME=b4_app_upgrade


log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Set To Input Database Name
DBName=$1
typeset -u DBName


# Remove From Previous Run
if [ -f ${SCRDIR}/ps_${DBName}_dw_create_grp_job.out ] ; then
   rm ${SCRDIR}/ps_${DBName}_dw_create_grp_job.out
fi



# Define Work Variables
SCRPTCNT=0

# Is Script Already Running ( this script designed to be in cron. When running from cron each execution gets 2 processes.
ps -ef > ${SCRDIR}/ps_${DBName}_dw_create_grp_job.out
wait
SCRPTCNT=`grep -i "DW_CREATE_GRP.sh" ps_${DBName}_dw_create_grp_job.out |grep -i ${DBName} |grep -v grep |wc -l`
echo $SCRPTCNT

if [ ${SCRPTCNT} -gt 2 ]; then
   echo "DW_CREATE_GRP Job - Overlap. Job Already Running for Database ${DBName}"
   mailx -s "DW_CREATE_GRP script Overlap! " ${MAILIDS1} < ps_${DBName}_dw_create_grp_job.out
   exit 0
fi


# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1


# Remove From Previous Run
if [ -f ${SCRDIR}/DW_CREATE_GRP.log ] ; then
   rm ${SCRDIR}/DW_CREATE_GRP.log
fi

# Remove From Previous Run
if [ -f ${SCRDIR}/dw_create_grp_flag.out ] ; then
   rm ${SCRDIR}/dw_create_grp_flag.out
fi

# Check For Restore Point
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool dw_create_grp_flag.out
select trim(count(*))
FROM AEDBA.HRP_UPGRADE_JOB_FLAG 
WHERE JOB_ID = 1 AND IS_JOB_ACTIVE = 'Y';
EOF


# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Checking for DW_CREATE_GRP JOB Flag in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Checking for DW_CREATE_GRP JOB Flag" ${MAILIDS1} < ${LOGFILE}
   exit 1
else
   log_console "Success Checking for DW_CREATE_GRP JOB Flag in Database " ${DBName}
   log_console " "
fi

CNT=`cat dw_create_grp_flag.out`
if [ ${CNT} -gt 0 ] ; then
   log_console "Flag for DW_CREATE_GRP JOB is Y for Database " ${DBName}
   log_console " "
   log_console "Setting Flag for DW_CREATE_GRP JOB back to N for Database" ${DBName}
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
   log_console "Error Encountered Updading DW_CREATE_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
   mailx -s "Error Encountered Updading DW_CREATE_GRP JOB Flag" ${MAILIDS} < ${LOGFILE} 
   exit 1
else
   log_console "Success Updating DW_CREATE_GRP JOB Flag back to N in Database " ${DBName}
   log_console " "
fi


echo "Starting Locking DW accounts"
log_console "Starting Locking DW accounts" 
log_console " "
nohup ${SCRDIR}/Lock_DW_users.sh ${DBName} >> $LOGFILE 2>&1
retn_code_1=$?

## Success or Failure ? ##
if [ $retn_code_1 -eq 0 ]
then
  echo "Locking DW Accounts completed with Success"
  log_console "Locking DW Accounts completed with Success" 
  log_console " "   
else
  echo "Error Locking DW Accounts!!!"
  log_console "Error Locking DW Users!!!"
  log_console " "
  exit 1
fi

echo "Starting DW GRP creation"
log_console "Starting DW GRP creation"
log_console " " 
nohup ${SCR}/create_guaranteed_restore_point.sh ${DBName} ${GRP_NAME} >> $LOGFILE 2>&1
retn_code=$?


## Success or Failure ? ##
if [ $retn_code -eq 0 ]
then
  echo "DW GRP creation completed with Success"
  log_console "DW GRP creation completed with Success"
  log_console " "
  mailx -s "DW GRP creation completed with Success" ${MAILIDS} < ${LOGFILE}
  exit 0
else
  echo "DW GRP creation completed with Errors"
  log_console "DW GRP creation completed with Errors"
  log_console " "
  mailx -s "DW GRP creation completed with Errors" ${MAILIDS} < ${LOGFILE}
  exit 1
fi


else
   log_console "FLAG for DW_CREATE_GRP JOB is N for Database " ${DBName}
   log_console " "
   log_console "Going back to sleep will wake up in 5 min to check again."
   log_console " " 
   exit 0
fi

