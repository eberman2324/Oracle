#!/bin/bash
######################################################################################################
#  kill_database_session.sh is called from an OEM metric extention call temp usage  
#
#  usage: $ . kill_database_session.sh   <target_db_name>  <target_db_sid> <target_db_serial#>
#
#
#  Maintenance Log:
#  1.0  11/2015         R. Ryan     New Script 
#  1.1  10/2016         R. Ryan     Corrected active instance check 
#  1.2  11/16/2016      R. Ryan     add bash_profile source and build level log
#  1.3  11/27/2017      R. Ryan     allowed script to be multithreaded
#  2.0  01/19/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/kill_session_$1_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 3 ]; then
  log_console "Usage: $0  target_db_name target_db_sid target_db_serial#"
  log_console Parms: $*
  exit 1
fi

log_console "Start kill session $2 $3 in $1  `uname -svrn` at `date` using $0"
log_console " "

export SESSION_ID=$2
export SERIAL_NO=$3
export ORACLE_SID=$1

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$ORACLE_SID$ | grep -v grep | grep -v $ORACLE_SID[0-z] >/dev/null
if test $? -gt 0; then
  log_console " "
  log_console "Oracle Instance is  not active"
  exit 1
fi
log_console " "

export ORAENV_ASK=NO
 
. oraenv >> $LOGFILE
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql
cat << label1 > $ORACLE_BASE/admin/$ORACLE_SID/sql/kill_session_${SESSION_ID}_${SERIAL_NO}_${ORACLE_SID}.sql

whenever sqlerror exit failure 1
spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/kill_session_${SESSION_ID}_${SERIAL_NO}_${ORACLE_SID}.out
alter system kill session '${SESSION_ID},${SERIAL_NO}' immediate;
spool off;
exit;


label1


sqlplus -S / as sysdba < $ORACLE_BASE/admin/$ORACLE_SID/sql/kill_session_${SESSION_ID}_${SERIAL_NO}_${ORACLE_SID}.sql >> $LOGFILE
if [ $? -gt 0 ] ; then
  log_console "Session Marked for kill"
else
  log_console  "Session killed successfully"
fi

log_console "kill session  complete  `uname -svrn` at `date` using $0 "
echo 


exit 0

