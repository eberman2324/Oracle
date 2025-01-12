#!/bin/bash
################################################################################################################3333333333333
#  psu_opt_in.sh is executed to opt back in of a puppet push off an oracle home after an opt out
#
#  usage: $  psu_opt_in.sh  <dbms_patched_version>   
#
#
#  Maintenance Log:
#  version 1.0 06/2017      R. Ryan     New Script 
#  version 2.0 01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#############################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

# End of functions


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/psu_opt_in_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  dbms_version "
  log_console Parms: $*
  exit 1
fi

VERSION=$1
CURRENT_RELEASE=` head -1 $SCRIPTS/README.txt | cut -f2 -d ' '`
grep $VERSION $SCRIPTS/next_4_psu.txt
if [ $? -gt 0 ] && [ $VERSION != $CURRENT_RELEASE ]; then
  log_console " "
  log_console "Invalid PSU release specified"
  echo  The next four PSU releases will be: `cat $SCRIPTS/next_4_psu.txt` | tee -a $LOGFILE
  exit 1
fi

echo "Start puppet push opt in of $VERSION on  `uname -svrn` at `date` using $0" >> $LOGFILE
#log_console " " 
#log_console "Review log file $LOGFILE for details"
log_console " "

if [ -d ${STD_DBMS_DIR}/app/oracle/product/${VERSION} ]; then
  log_console "Oracle DBMS software version $VERSION is already installed, no action taken"
else
  if [ -f $STD_STAGE_DIR/oracle_setup_status_dbms_${VERSION}_initial_successful ]; then
    rm -f $STD_STAGE_DIR/oracle_setup_status_dbms_${VERSION}_initial_successful
    rm -f $STD_STAGE_DIR/oracle_setup_status_dbms_${VERSION}_opt_out
    log_console "Oracle DBMS software version $VERSION puppet push has been enabled"
  else
     log_console "Oracle DBMS software version $VERSION puppet push opt out has not been requested, no action taken"
  fi
fi
log_console " "
echo "Puppet push opt in of  $VERSION  complete on  `uname -svrn` at `date` using $0 " >> $LOGFILE
exit 0

