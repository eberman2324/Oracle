#!/bin/bash
##############################################################################################################################################################
#
#  usage: $ . purge_stby_archive_logs  <db_name>  
#
#
#  Maintenance Log:
#  version 1.0 07/2018      R. Ryan     New Script 
#  version 2.0 01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
################################################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/purge_stdby_archive_logs_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start STBY Archive log purge of $1 on  `uname -svrn` at `date` using $0"
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
export ORAENV_ASK=NO
. oraenv >> $LOGFILE

#----------------------------------------------------------
# Purge Archive logs 
#----------------------------------------------------------


log_console " "
log_console "Starting RMAN archive log backup........."
rman target / <<EOF | tee -a $LOGFILE
delete noprompt archivelog all;
EOF
if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "ERROR ---> Archive Log purge failed in rman"
else
   log_console "Archive log purge successful"
fi



log_console " "
log_console "Archive log purge of  $ORACLE_SID  complete on  `uname -svrn` at `date` using $0 "
exit 0

