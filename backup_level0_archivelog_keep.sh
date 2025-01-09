#!/bin/sh
##############################################################################################################################################################
#
#  usage: $ . backup_level0_archivelog_keep  <db_name>  
#
#
#  Maintenance Log:
#  version 1.0 12/2019      E. Berman     New Script 
#
################################################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}


DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=/home/oracle/eb/logs
LOGFILE=$LOGDIR/backup_level0_archivelog_keep_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start level0_archivelog keep backup of $1 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1 | grep -v grep | grep -v $1[0-z] 
if test $? -eq 1; then
  ps -ef | grep pmon_$1 | grep -v grep | grep -v $1[0-z]>> $LOGFILE
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
# Backup level0_archivelog_keep 
#----------------------------------------------------------


log_console " "
log_console "Starting RMAN level0_archivelog_keep backup........."
#rman target / <<EOF >>$LOGFILE
rman target / catalog ${ORACLE_SID}/${RCATPASS}@${RCATDB}<<EOF | tee -a $LOGFILE
backup incremental level 0 database tag='HEPYQA2_preupgrade' keep until time 'sysdate+100' plus archivelog tag='HEPYQA2_preupgrade' keep until time 'sysdate+100';
EOF
if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "ERROR ---> level0_archivelog_keep backup failed in rman"
else
   log_console "level0_archivelog_keep backup  successful"
fi



log_console " "
log_console "level0_archivelog_keep backup of  $ORACLE_SID  complete on  `uname -svrn` at `date` using $0 "
exit 0

