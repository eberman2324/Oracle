#!/bin/bash
######################################################################################################
#
#  usage: $ . create_restore_point.sh   <target_db_name>  <restore_point_name> 
#
#
#  Maintenance Log:
#  1.0  11/2015      R. Ryan          New Script 
#  1.1  10/2016      R. Ryan          Corrected active instance check
#  1.2  10/2016      R. Ryan          added sourcing of bash_profile
#  1.3  03/2018      R. Ryan          Corrected formatting issues.
#  2.0  01/2021      R. Ryan          Modified script to accomodate new joint CVS/Aetna standard
#  2.1  08/2022      T. Schloendorn   Added call to heartbeat script before save point creation
#                                     and also listing database name in output.
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/create_restore_point_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 2 ]; then
  log_console "Usage: $0  target_db_name restore_point_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start create restore point $2  in $1  `uname -svrn` at `date` using $0"
log_console " "


# Check to see if Oracle Instance is active
ps -ef | grep pmon_$ORACLE_SID$ | grep -v grep | grep -v $ORACLE_SID[0-z] >/dev/null
if test $? -gt 0; then
  log_console " "
  log_console "Oracle Instance is  not active"
  exit 1
fi
log_console " "
export RESTORE_POINT="$2"
export ORACLE_SID=$1

# Confirm Valid PAYOR DataBase
case ${ORACLE_SID} in
     "HEDWDEV"|"HEDWDEV2"|"HEDWDEV3"|"HEDWMGR"|"HEDWMGR2"|"HEDWQA2"|"HEDWQA3"|"HEDWSTS"|"HEDWTST"|"HEDWUAT")
     ;;
     "HEDWQA")
     log_console " "
     log_console "HEDWQA has a physical standby database. Log shipping should be suspended instead."
     exit 1
     ;;
     *)
     log_console " "
     log_console "${ORACLE_SID} Not A Recognized DW DataBase - Script Aborting"
     exit 1
     ;;      
esac

export ORAENV_ASK=NO
 
. oraenv >> $LOGFILE
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql
cat << label1 > $ORACLE_BASE/admin/$ORACLE_SID/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.sql
set linesize 160 trimspool on
spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out
select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Current Time" from v\$database;
create restore point "${RESTORE_POINT}";
prompt ----------------------------------------;
prompt  Available Restore Points for ${ORACLE_SID};
prompt ----------------------------------------;
col name format a36
col database_incarnation# format 99999999999 head INCARNATION
col scn  format 99999999999999999999
col time format a35
select name, database_incarnation#, scn, time from v\$restore_point;
spool off;
exit;


label1

# Call Heartbeat
/home/oracle/tls/rman/heartbeat.ksh ${ORACLE_SID} AEDBA

cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.sql > $ORACLE_PATH/runthis.sql

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Restore Point Create failed"
fi
cat ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out
rm $ORACLE_PATH/runthis.sql

log_console " "
log_console "create restore point create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out  `uname -svrn` at `date` using $0 "
log_console " "

echo 

exit 0

