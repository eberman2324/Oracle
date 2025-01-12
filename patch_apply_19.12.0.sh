#!/bin/bash
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
  echo "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/patch_apply_19.12.0_$1_$DATEVAR.out

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
export ORACLE_HOME=${STD_DBMS_DIR}/app/oracle/product/19.12.0/db_1
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

#-------------------------------------------------------
# Open PDBs for patching if the database is a CDB 
#------------------------------------------------------

export IS_CDB=$LOGDIR/is_cdb_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select cdb from v\$DATABASE;
exit;" | sqlplus -s / as sysdba > $IS_CDB

export IS_CDB=$(tail -1 $IS_CDB |sed -e 's/ //g')


if [ $IS_CDB = 'YES' ]; then
  log_console "Database $ORACLE_SID is a container database, opening all PDBs for patching....."
  sqlplus -S  <<EOF
  connect / as sysdba
  whenever sqlerror exit failure 1
  alter pluggable database all open upgrade;
EOF
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> PDB open  Failed"
    exit 1
  fi
fi


#------------------------------------------------------------
#   Apply data patch
#------------------------------------------------------------
$ORACLE_HOME/OPatch/datapatch -verbose | tee -a $LOGFILE
if [ ${PIPESTATUS[0]} -gt 0 ] ; then
  grep ORA-04068 $LOGFILE
  if [ $? -gt 0 ] ; then
    log_console "Error ---> Data patch apply failed"
    exit 1
  else
    log_console "datapatch failed due to known issue, retrying datapatch as prescribed in doc ID 2568305.1......"
    $ORACLE_HOME/OPatch/datapatch -verbose | tee -a $LOGFILE
    if [ ${PIPESTATUS[0]} -gt 0 ] ; then
      log_console "Error ---> Data patch apply failed"
      exit 1
    fi
  fi  
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

