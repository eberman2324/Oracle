#!/bin/sh
######################################################################################################
#  patch_apply_xx.xx.xx.xx.sh is executed to execute post patch actions
#
#  usage: $ . patch_apply_xx.xx.xx.xx.sh   <target_db_name>  
#         this script is called from patch_db.sh
#
#
#  Maintenance Log:
#  05/2016      R. Ryan     New Script 
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" 
}

DATEVAR=$(date +'%Y%m%d_%s')

if [ $# -ne 1 ]; then
  log_console "Usage: $0  target_db_name"
  log_console Parms: $*
  exit 1
fi

log_console "Start DB patch apply of $1  `uname -svrn` at `date` using $0"
log_console " " 

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] 
if test $? -eq 0; then
  log_console " "
  log_console "Oracle Instance is  active...stop it before attempting patch"
  exit 1
fi
log_console " "

export ORACLE_SID=$1
export ORACLE_HOME=/orahome/u01/app/oracle/product/12.1.0.2.200114/db_1
export PATH=$ORACLE_HOME/bin:$PATH



#------------------------------------------------------------
#  Start database in upgrade mode, required for JVM patch
#------------------------------------------------------------

sqlplus -S  <<EOF  
connect / as sysdba
whenever sqlerror exit failure 1
startup upgrade;
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Database startup  Failed"
  exit 1
fi

#------------------------------------------------------------
#   Apply data patch
#------------------------------------------------------------
$ORACLE_HOME/OPatch/datapatch -verbose
if [ $? -gt 0 ] ; then
  log_console "Error ---> Data patch apply failed"
  exit 1
fi

#------------------------------------------------------------
#  Shutdown database 
#------------------------------------------------------------

sqlplus -S  <<EOF  
connect / as sysdba
whenever sqlerror exit failure 1
shutdown immediate;
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Database shutdown  Failed"
  exit 1
fi

log_console "Patch apply of $ORACLE_SID  to  $VERSION  complete on  `uname -svrn` at `date` using $0 "
echo 


exit 0

