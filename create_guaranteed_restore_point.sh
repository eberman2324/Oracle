#!/bin/bash
######################################################################################################
#
#  usage: $ . create_guranteed_restore_point.sh   <target_db_name>  <restore_point_name> 
#
#
#  Maintenance Log:
#  1.0  02/2021      R. Ryan     New Script 
#  1.2  04/2021      R. Ryan     Suspend OEM jobs for standby databases.
#  1.3  08/2021      R. Ryan     removed prompt for sys password, password is now fetched from BT.
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

validate_password () {
  echo ${STDBY_CONNECT_STRING:1}
  echo $password
  sqlplus -S sys/${password}@${STDBY_CONNECT_STRING:1} as sysdba<<eof1 >> $LOGFILE
  whenever sqlerror exit 1
  exit;
eof1

  if [ $? -gt 0 ]; then
#    log_console "Invalid Password, try again"
     log_console "Invalid Password found in BT, make sure the password for account ${SERVER_NAME}_${ORACLE_SID}_sys is valid"
    exit 1
  fi
}

# Function : SUSPEND/RESUME OEM jobs
change_job_status () {

log_console " "


case ${SERVER_NAME: -1} in
    p)
     ORACLEDBA_HOST='xoraclddbm1p'
     ORACLEDBA_SID='EMCLDPRD'
    ;;
    *)
     ORACLEDBA_HOST='xoraclddbw1d'
     ORACLEDBA_SID='EMCLDDEV'
    ;;
esac

ORACLEDBAPASS=`fetch_db_bt.bash.x -a DBA -r "create grp" -P oracledba -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`



$ORACLE_BASE/product/emcli/emcli logout >> $LOGFILE
$ORACLE_BASE/product/emcli/emcli login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE

case $1 in
   suspend)
      log_console "The following Jobs are scheduled or running in OEM"
      log_console " "
      $ORACLE_BASE/product/emcli/emcli get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${ORACLE_SID}_${SERVER}:oracle_database | tee -a $LOGFILE
      log_console " "
      $ORACLE_BASE/product/emcli/emcli $1_job  -owner=ORACLEDBA -targets=${ORACLE_SID}_${SERVER}:oracle_database | tee -a $LOGFILE
      ;;
   resume)
      $ORACLE_BASE/product/emcli/emcli $1_job  -owner=ORACLEDBA -targets=${ORACLE_SID}_${SERVER}:oracle_database | tee -a $LOGFILE
      log_console "The following Jobs are scheduled or running in OEM"
      log_console " "
      $ORACLE_BASE/product/emcli/emcli get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${ORACLE_SID}_${SERVER}:oracle_database | tee -a $LOGFILE
      ;;
esac

if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "Job Status Change Failed....."
  $ORACLE_BASE/product/emcli/emcli logout >> $LOGFILE
  log_console " "
  return 1
else
  $ORACLE_BASE/product/emcli/emcli logout >> $LOGFILE
  log_console " "
  return 0
fi
}
# End of functions


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/create_guranteed_restore_point_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 2 ]; then
  log_console "Usage: $0  target_db_name restore_point_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start create guranteed restore point $2  in $1  `uname -svrn` at `date` using $0"
log_console " "


# Check to see if Oracle Instance is active
ps -ef | grep pmon_$ORACLE_SID$ | grep -v grep | grep -v $ORACLE_SID[0-z] >/dev/null
if test $? -gt 0; then
  log_console " "
  log_console "Oracle Instance is  not active"
  exit 1
fi
log_console " "
export RESTORE_POINT=$2
export ORACLE_SID=$1
export ORAENV_ASK=NO
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`
RET_CD=0
 
. oraenv >> $LOGFILE
#------------------------------------------------------------
#   Enable Flash Back logging on  Primary databases
#------------------------------------------------------------
#log_console "Enabling flashback logging on primary database...."
#echo 'alter database flashback on;' | sqlplus / as sysdba >> $LOGFILE
#if [ ${PIPESTATUS[1]} -ne 0 ] ; then
#  log_console "Enabling flashback logging on ${ORACLE_SID}_${SERVER} has failed"
#  log_console " "
#  exit 1
#else
#  log_console "Flashback logging has been enabled on ${ORACLE_SID}_${SERVER}"
#  log_console " "
#fi


#------------------------------------------------------------
#   Enable Flash Back logging on  Standby databases
#------------------------------------------------------------
export STANDBY_COUNT=$LOGDIR/standby_count_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(*) from v\$DATAGUARD_CONFIG where dest_role='PHYSICAL STANDBY';
exit;" | sqlplus -s / as sysdba > $STANDBY_COUNT

export STANDBY_COUNT=$(tail -1 $STANDBY_COUNT |sed -e 's/ //g')

if [ $STANDBY_COUNT -eq 0 ] ; then
 log_console "This database is not configured with Data Guard or log_transport has been disabled for all standby's"
else
 log_console "This database has $STANDBY_COUNT standby database(s), enabling flashback loging on each....."
 PORT=`dgmgrl -echo / "show database verbose '${ORACLE_SID}_${SERVER}'" | grep StaticConnect | cut -d = -f7 | cut -b 1-4`
 password=`fetch_db_bt.bash.x -a DBA -r "create grp" -P sys -h ${SERVER}  -s ${ORACLE_SID} -p ${PORT} 2>/dev/null | tr -d '[[:space:]]'`

# unset password
# prompt="enter sys password:"
#
#    while IFS= read -p "$prompt" -r -s -n 1 char
#            do
#                    if [[ $char == $'\0' ]]
#                            then
#                                    break
#                    fi
#                    prompt='*'
#                    password+="$char"
#            done
#
#   log_console " "

 export STANDBY_SERVERS=$LOGDIR/standby_servers_$ORACLE_SID.log
 echo "set echo off ver off pages 0 trims on head off feed off
 select listagg(db_unique_name,'_') within group (order by db_unique_name) names from v\$DATAGUARD_CONFIG where dest_role='PHYSICAL STANDBY';
 exit;" | sqlplus -s / as sysdba > $STANDBY_SERVERS

 #export STANDBY_SERVERS=$(tail -1 $STANDBY_SERVERS |sed -e 's/ //g'| cut -d _ -f2)
 export STANDBY_SERVERS=$(tail -1 $STANDBY_SERVERS |sed -e 's/ //g'| cut -d _ -f2,4 | tr '_' ' ')

 for SERVER in  $STANDBY_SERVERS
  do
    export STDBY_CONNECT_STRING=`dgmgrl -echo / "show database verbose '${ORACLE_SID}_${SERVER}'" | grep StaticConnect | cut -d = -f2-9`
    validate_password
    dgmgrl -echo / "edit database '${ORACLE_SID}_${SERVER}' set state=apply-off" | tee -a $LOGFILE
    if [ $? -ne 0 ] ; then
      log_console "Disabling log apply on ${ORACLE_SID}_${SERVER} has failed"
      log_console " "
      exit 1
    else
      log_console "Log apply has been disabled on ${ORACLE_SID}_${SERVER}"
      log_console " "
    fi

    echo -e 'whenever sqlerror exit 1 \n set echo on \n alter database flashback on;' | sqlplus -S sys/$password@${STDBY_CONNECT_STRING:1} as sysdba | tee -a $LOGFILE
    if [ ${PIPESTATUS[1]} -ne 0 ] ; then
      log_console "Enabling flashback logging on ${ORACLE_SID}_${SERVER} has failed"
      log_console " "
      exit 1
    else
      log_console "Flashback logging has been enabled on ${ORACLE_SID}_${SERVER}"
      log_console " "
    fi
 
    dgmgrl -echo / "edit database '${ORACLE_SID}_${SERVER}' set state=apply-on" | tee -a $LOGFILE
    if [ $? -ne 0 ] ; then
      log_console "Enabling log apply on ${ORACLE_SID}_${SERVER} has failed"
      log_console " "
      exit 1
    else
      log_console "Log apply has been enabled on ${ORACLE_SID}_${SERVER}"
      log_console " "
    fi

    log_console "Attemping to suspend OEM Jobs for ${ORACLE_SID}_${SERVER}"
    change_job_status suspend
    if [ $? -gt  0 ] ; then
      RET_CD=10
      log_console "Job suspension for ${ORACLE_SID}_${SERVER} has failed"
    else
      log_console "OEM Jobs have for ${ORACLE_SID}_${SERVER} been suspended"
    fi

  done
fi

#------------------------------------------------------------
#  Create Guranteed Restore Point 
#------------------------------------------------------------

mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql
cat << label1 > $ORACLE_BASE/admin/$ORACLE_SID/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.sql

spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out
create restore point ${RESTORE_POINT} GUARANTEE FLASHBACK DATABASE;
prompt ----------------------------------------;
prompt  Available Restore Points for ${ORACLE_SID};
prompt ----------------------------------------;
col name format a36
col database_incarnation# format 99999999999 head INCARNATION
col scn  format 999999999999999
col time format a31
set linesize 160
select name, database_incarnation#, scn, time, GUARANTEE_FLASHBACK_DATABASE from v\$restore_point;
spool off;
exit;


label1


cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.sql > $ORACLE_PATH/runthis.sql


sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Restore Point Create failed"
  cat ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out
  rm $ORACLE_PATH/runthis.sql
  exit 1
fi
cat ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_restore_point_${RESTORE_POINT}_${ORACLE_SID}.out
rm $ORACLE_PATH/runthis.sql

log_console "create restore point $RESTORE_POINT on $ORACLE_SID  `uname -svrn` at `date` using $0 "
echo 


exit $RET_CD

