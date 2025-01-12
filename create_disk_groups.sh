#!/bin/bash
###########################################################################################################################
#  create_disk_groups,sh is executed to create all  standard build database ASM disk groups   
#
#  usage: $ . create_disk_groups.sh   
#
#
#  Maintenance Log:
#  1.0  12/2019      R. Ryan     New Script 
#  2.0  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
###########################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

#End of functions

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/create_disk_groups_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


log_console "Start disk group creation on  `uname -svrn` at `date` using $0 $*"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "


sqlplus -S  <<EOF  >>$LOGFILE
connect / as sysasm
whenever sqlerror exit failure 1
@create_disk_groups.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Create Disk Groups Failed"
  exit 1
else
  log_console  "Create Disk Groups Successful"
fi

log_console " "
log_console "Create disk groups complete on  `uname -svrn` at `date` using $0 "

exit 0

