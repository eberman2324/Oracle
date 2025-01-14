#!/bin/bash


# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi








#new standard
# Define Mail Distribution and variables
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/monitor/longrunners/cust_mail_list`
DBAMAILIDS=`paste -s /oradb/app/oracle/local/scripts/monitor/longrunners/dba_mail_list`
LOGFILE=/oradb/app/oracle/local/scripts/monitor/longrunners/PY_LONG_RUNNERS.log
CURDIR=/oradb/app/oracle/local/scripts/monitor/longrunners






cd ${CURDIR}

log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Set To Input Database Name
DBName=$1
typeset -u DBName

# Set DayTime
MMDDYYYY=`date +"%m%d%Y"`




##########################################################################################################
ps -ef | grep pmon | grep -v grep > pmon.out
ps -ef| grep ${DBName} pmon.out |awk '{ print $8 }' | tail -c 10 > instname.out
DBName=`cat instname.out`



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

##########################################################################################################

# Remove From Previous Run
if [ -f ${CURDIR}/PY_LONG_RUNNERS.log ] ; then
   rm ${CURDIR}/PY_LONG_RUNNERS.log
fi


# Remove From Previous Run
if [ -f ${CURDIR}/py_long_runners_sessions.out ] ; then
   rm ${CURDIR}/py_long_runners_sessions.out
fi


# Check For Restore Point
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool py_long_runners_sessions.out
select trim(count(*))
from v\$session
where  SCHEMANAME NOT IN ( 'SYS','DBSNMP') AND LAST_CALL_ET >=7200 and SQL_ID IS NOT NULL  and EVENT = 'SQL*Net message from client';
spool off
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   log_console "Error Encountered Checking Long running session Count in Database " ${DBName}
   mailx -s "Error Encountered Checking Long running session Count in Database" ${DBAMAILIDS} < ${LOGFILE}
   exit 1
else
   log_console "Success Checking for Long running session Count in Database " ${DBName}
fi


# Change Permissions
#chmod 600 py_long_runners_sessions.out

SID_CNT=`cat ${CURDIR}/py_long_runners_sessions.out`
#SID_CNT=`${CURDIR}/py_long_runners_sessions.out`
log_console "PY Long running session count: " ${SID_CNT}
if [ ${SID_CNT} -gt 0 ] ; then
   log_console "Long running Session Count > 0 in Database " ${DBName}
   log_console "Building PY Long runners report for Database " ${DBName}
# Check Long running sessions
sqlplus > /dev/null <<EOF
/ as sysdba
@PY_long_runners.sql ${MMDDYYYY}
EOF

# If Error
if [ $? -ne 0 ] ; then
   log_console "Error Encountered Running PY Long Runners Report"
   mailx -s "Error Encountered Running PY Long Runners Report" ${DBAMAILIDS} < PY_LONG_RUNNING_SESSIONS_${MMDDYYYY}.out
else
   log_console  "PY Long Running Sessions Report completed. Emailing now"
   #mailx -s " PY Long Running Sessions Report" ${MAILIDS} < PY_LONG_RUNNING_SESSIONS_${MMDDYYYY}.out
   mailx -s " PY Long Running Sessions Report" ${MAILIDS} < py_long_runners_report.sql
fi

# Change Permissions
chmod 600 PY_LONG_RUNNING_SESSIONS_${MMDDYYYY}.out

else
   log_console "Not found any long running SID sessions at this moment"
fi

# remove old output files
/usr/bin/find ${CURDIR} -name \*.out -mtime +3 -exec rm -f {} \;

# Change Permissions
chmod 600 PY_long_runners.sql 

