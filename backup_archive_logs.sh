#!/bin/bash
##############################################################################################################################################################
#
#  usage: $ . backup_archive_logs  <db_name>  
#
#
#  Maintenance Log:
#  version 1.0 07/2018      R. Ryan     New Script 
#  version 1.2 10/2020      R. Ryan     Set the RCATPASS variable since it was removed from oraenv 
#  version 2.0 01/2021      R. Ryan     Modified scrript to accomodate new joint CVS/Aetna standard
#
################################################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/backup_archive_logs_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start Archive log backup of $1 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] 
if test $? -eq 1; then
  ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z]>> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active...start it before attempting patch"
  exit 1
fi
log_console " "

export ORACLE_SID=$1
#export CAT_DB=$3
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------
log_console ' '
shopt -s expand_aliases
export ORAENV_ASK=NO
. oraenv >> $LOGFILE
export RCATPASS=`rcatpass`


#----------------------------------------------------------
# Backup Archive logs 
#----------------------------------------------------------


log_console " "
log_console "Starting RMAN archive log backup........."

if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] ; then
   export CAT_OWN=$SERVER_NAME
else
   export CAT_OWN=$ORACLE_SID
fi

rman target / <<EOF | tee -a $LOGFILE
connect catalog ${CAT_OWN}/${RCATPASS}@${RCATDB}
backup archivelog all delete input;
EOF

if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "ERROR ---> Archive Log Backup failed in rman"
else
   log_console "Archive log backup  successful"
fi


log_console " "
log_console "Archive log backup of  $ORACLE_SID  complete on  `uname -svrn` at `date` using $0 "
exit 0

