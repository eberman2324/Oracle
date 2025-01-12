#!/bin/bash
##############################################################################################################################################################
#  change_oem_job_status is executed to suspend or resume all OEM job executions for a specified OEM database target
#
#  usage: $ change_oem_job_status.sh  <oem database target name> <action>  
#
#
#  Maintenance Log:
#  version 1.0 07/2021      R. Ryan     New Script 
#
################################################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
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

ORACLEDBAPASS=`fetch_db_bt.bash.x -a DBA -r "suspend jobs" -P oracledba -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`

$ORACLE_BASE/product/emcli/emcli logout >> $LOGFILE
$ORACLE_BASE/product/emcli/emcli login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE

case $1 in
   suspend)
      log_console "The following Jobs are scheduled or running in OEM"
      log_console " "
      $ORACLE_BASE/product/emcli/emcli get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${TARGET_NAME}:oracle_database | tee -a $LOGFILE
      log_console " "
      $ORACLE_BASE/product/emcli/emcli $1_job  -owner=ORACLEDBA -targets=${TARGET_NAME}:oracle_database | tee -a $LOGFILE
      ;;
   resume)
      $ORACLE_BASE/product/emcli/emcli $1_job  -owner=ORACLEDBA -targets=${TARGET_NAME}:oracle_database | tee -a $LOGFILE
      log_console "The following Jobs are scheduled or running in OEM"
      log_console " "
      $ORACLE_BASE/product/emcli/emcli get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${TARGET_NAME}:oracle_database | tee -a $LOGFILE
      ;;
   *)
      log_console "Invalid job action specified, please specify suspend or resume"
      log_console " "
      return 1
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
LOGFILE=$LOGDIR/change_oem_job_status_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 2 ]; then
  log_console "Usage: $0  <oem_database_target_name> <action(suspend or resume)> "
  log_console Parms: $*
  exit 1
fi

log_console "Start OEM job status change of $1 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`


#------------------------------------------------------------
# change OEM Job status
#------------------------------------------------------------
log_console "Attemping to $2 OEM Jobs for $1"
export TARGET_NAME=$1
change_job_status $2
if [ $? -gt  0 ] ; then
  log_console "Job $2 has failed"
else
  log_console "OEM Job statuses changed to $2"
fi

log_console " "
log_console "$2 of jobs for target $1  complete on  `uname -svrn` at `date` using $0 "
exit 0

