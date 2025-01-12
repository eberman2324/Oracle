#!/bin/bash
######################################################################################################
#  remove_audit_trail_timestamps.sh is executed to remove old audit trail timestamps left from clonning
#
#  usage: $ . clone_sb_db.sh  <target_db_name>  
#
#
#  Maintenance Log:
#  1.0  11/2015      R. Ryan     New Script
#  1.1  11/2015      R. Ryan     Corrected Active Instance check
#  2.0  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#####################################################################################################
log_console () {
  echo "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/remove_audit_trail_timestamps_$DATEVAR.out


if [ $# -ne 1 ]; then
  log_console "Usage: $0 target_db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start remove audit trail time stamps from  $1  `uname -svrn` at `date` using $0"
log_console " "
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] | grep -v grep
if test $? -gt 0; then
  log_console " "
  log_console "Oracle Instance $1 is not active...start database or correct input"
  exit 1
fi
log_console " "

export ORACLE_SID=$1
export ORAENV_ASK=NO

. oraenv >> $LOGFILE

export DB_ID_LIST=$SQLPATH/db_id_list_$PRIMARY_DB.log
echo "set echo off ver off pages 0 trims on head off feed off
select unique database_id from DBA_AUDIT_MGMT_LAST_ARCH_TS minus select dbid from v\$database;
exit;" | sqlplus -s /  as sysdba > $DB_ID_LIST

export DB_ID_LIST=$(tail -1 $DB_ID_LIST |sed -e 's/ //g')
log_console "List Of Audit Trail timestamp DB_IDs to delete: $DB_ID_LIST"

for DBID in $DB_ID_LIST
  do
    log_console "Removing audit trail snaps shots for $DBID"
    sqlplus -S / as sysdba <<EOF >> $LOGFILE
    whenever sqlerror exit failure 1
    exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,DATABASE_ID=>$DBID);
    exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,DATABASE_ID=>$DBID);
    exit;
EOF
    if [ $? -gt 0 ] ; then
      log_console "Error -----> Removal of audit trail timestamp for $DBID failed"
    else
      log_console "Removal of audit trail timestamps for $DBID successful"
    fi

  done

log_console " "
log_console "Remove Audit Trail Time Stamps from  $1 complete  `uname -svrn` at `date` using $0 "
echo


exit 0

