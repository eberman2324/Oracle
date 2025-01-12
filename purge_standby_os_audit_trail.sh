#!/bin/bash
######################################################################################################
#  purge_standby_os_audit_trail.sh is executed to purge Standby database OS audit files 
#
#  usage: $ . purge_standby_os_audit_trail.sh <ORACLE_SID>
#
#
#  Maintenance Log:
#  12/2015      R. Ryan     New Script 
#  10/2016      R. Ryan     Correct active instance check
#  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

. ~/.bash_profile > /dev/null

if [ $# -ne 1 ]; then
  log_console "Usage: $0  db_name "
  log_console Parms: $*
  exit 1
fi

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/purge_standby_os_audit_trail_$1_$DATEVAR.out

echo -e '\n'Start Standby database for $1 audit trail purge  `uname -svrn` at `date` using $0 | tee -a $LOGFILE
echo 

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z]
if test $? -ne 0; then
  ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active...start the daabase before executing the purge"
  exit 1
fi
log_console " "

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

export ORACLE_SID=$1
export ORAENV_ASK=NO
. oraenv 

#------------------------------------------------------------
# Check if database is a standby 
#------------------------------------------------------------
export DB_ROLE=$SQLPATH/db_role_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select  database_role from v\$database;
exit;" | sqlplus -S / as sysdba > ${DB_ROLE}

export DB_ROLE=$(tail -1 ${DB_ROLE} |sed -e 's/ //g')

log_console "Database Role: ${DB_ROLE}"

if [ ${DB_ROLE} != 'PHYSICALSTANDBY' ] ; then
   log_console "Database $ORACLE_SID on `hostname` is not a physical standby database"
   log_console "Audit trail will be purged by dbms_scheduler job DAILY_OS_AUDIT_PURGE_JOB"
   exit 1
fi

#---------------------------------------------------------------------------
#  Get Audit Trail Location
#---------------------------------------------------------------------------
export AUDIT_LOC=$SQLPATH/audit_loc_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select  value from v\$parameter where name = 'audit_file_dest';
exit;" | sqlplus -S / as sysdba > $AUDIT_LOC

export AUDIT_LOC=$(tail -1 $AUDIT_LOC |sed -e 's/ //g')
log_console "Audit Trail Location: $AUDIT_LOC"



#------------------------------------------------------------
#  Purge Standby  Audit files older then 30 days
#------------------------------------------------------------
echo audit files prior to purge `ls -l $AUDIT_LOC | wc -l` | tee -a $LOGFILE

find $AUDIT_LOC -name '*.aud' -mtime +30 -exec rm -f {} \;

echo audit files after purge `ls -l $AUDIT_LOC | wc -l ` | tee -a $LOGFILE

echo -e '\n'Purge of Standby Audit Trail on $ORACLE_SID complete  `uname -svrn` at `date` using $0 | tee -a $LOGFILE
echo 


exit 0

