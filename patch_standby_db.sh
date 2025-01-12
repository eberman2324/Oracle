#!/bin/bash
######################################################################################################
#  patch_standby_db.sh is executed to patch a standby database  this script is called from 
#                      patch_db.sh
#
#  usage: $ . patch_standby_db.sh  <dbms_patched_version> <target_instance_name>  
#
#
#  Maintenance Log:
#  version 1.0 11/2015         R. Ryan     New Script 
#  version 1.1 03/16/2015      R. Ryan     add oracle_home symbolic link
#  version 1.2 03/30/2015      R. Ryan     corrected  symbolic link check
#  version 1.3 01/14/2016      R. Ryan     corrected JAVA_HOME issue
#  version 1.4 02/20/2017      R. Ryan     corrected bash_completion.d issue
#  version 1.5 03/26/2018      R. Ryan     add listener setenv update for TNS_ADMIN variable
#  version 1.6 01/17/2019      R. Ryan     corrected issue with symbolic link creation
#  version 2.0 01/17/2019      R. Ryan     Added support for Active Dataguard standby databases
#  version 2.1 09/26/2019      R. Ryan     Copied extproc.ora to new oracle home to support databases using Voltage
#  version 2.2 09/30/2019      R. Ryan     Corrected issue with ADG check.
#  version 2.3 01/24/2019      R. Ryan     Extended support to post 12c databases.
#  version 2.4 01/12/2019      R. Ryan     Corrected issue istroducted when the TSN_ADMIN variable was added to oraenv
#  version 3.0 01/19/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/patch_standby_db_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 2 ]; then
  log_console "Usage: $0  dbms_version target_db_name"
  log_console Parms: $*
  exit 1
fi

log_console "Start DB patching of $2 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$2$ | grep -v grep 
if test $? -eq 1; then
  ps -ef | grep pmon_$2$ | grep -v grep >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active...start it before attempting patch"
  exit 1
fi
log_console " "

export ORACLE_SID=$2
export VERSION=$1
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`


if [ -d ${STD_DBMS_DIR}/app/oracle/product/${VERSION} ]; then
  log_console "Oracle DBMS software version $VERSION is installed, continuing with patch apply"
else
  log_console "Oracle DBMS software version $VERSION is not intalled. Ensure $VERSION is installed before attempting patch"
  exit 1
fi

ORATAB=/etc/oratab
grep $ORACLE_SID $ORATAB >/dev/null 2>&1
if [ $? -eq 0 ]; then
  log_console "Database exists in ORATAB, continuing with patch apply"
else
  log_console "Database is not present in /etc/oratab, make sure $ORACLE_SID is present before performing patch apply "
  exit 1
fi 


#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

log_console ' '
export ORACLE_SID=$2
export ORAENV_ASK=NO
. oraenv >> $LOGFILE
export TNS_ADMIN=$ORACLE_BASE/product/$VERSION/db_1/network/admin

#------------------------------------------------------------
#  Check to ensure database is on correct release
#------------------------------------------------------------
cat << label1 > $ORACLE_PATH/runthis.sql
set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select version from v\$instance;
exit;
label1

log_console " "
CURRENT_RELEASE=(`sqlplus -s / as sysdba<<eof1
@runthis.sql
eof1`)

if [ $? -gt 0 ]; then
  log_console "Database version Checked failed."
  exit 1
fi

log_console " "
if [ `echo $CURRENT_RELEASE | cut -d '.' -f1` > 12 ] ; then
  if [ `echo $CURRENT_RELEASE | cut -d '.' -f1` = `echo $VERSION | cut -d '.' -f1` ] ; then
    log_console "Database is at the proper release to apply this patch, continuing with the patch apply"
  else
    log_console "Database is not at the requested patch apply release,  upgrade the database instead of attempting the patch apply"
    exit 1
  fi
else
  if [ `echo $CURRENT_RELEASE | cut -d '.' -f1,2,3,4` = `echo $VERSION | cut -d '.' -f1,2,3,4` ] ; then
    log_console "Database is at the proper release to apply this patch, continuing with the patch apply"
  else
    log_console "Database is not at the requested patch apply release,  upgrade the database instead of attempting the patch apply"
    exit 1
  fi
fi



#------------------------------------------------------------
#   Shutdown Database and Listener
#------------------------------------------------------------
srvctl disable listener -l $ORACLE_SID >> $LOGFILE
srvctl stop listener -l $ORACLE_SID >> $LOGFILE
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Listener shutdown Failed"
  exit 1
fi

srvctl stop database -d ${ORACLE_SID}_${SERVER_NAME}
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Database shutdown Failed"
  exit 1
fi

srvctl config database -d ${ORACLE_SID}_${SERVER_NAME} | grep 'read only'
if [ $? -eq 0 ]; then
  ADG=true
  log_console " "
  log_console "Standby database is configured with Active Dataguard, setting startoption to mount for patch apply......"
  srvctl modify database -d ${ORACLE_SID}_${SERVER_NAME} -startoption MOUNT
  log_console "Start option mount has been set."
else
  ADG=false
fi

#------------------------------------------------------------
#   Copy DBS files
#------------------------------------------------------------
echo "DBS files to be moved........." >> $LOGFILE
ls -ltr  $ORACLE_HOME/dbs/*${ORACLE_SID}* >> $LOGFILE
mv $ORACLE_HOME/dbs/*${ORACLE_SID}* $ORACLE_BASE/product/${VERSION}/db_1/dbs
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> DBS file move  Failed"
  exit 1
fi
log_console " "
log_console "DBS files for ${ORACLE_SID} have been moved to $ORACLE_BASE/product/$VERSION/dbs" 
echo "${ORACLE_SID} files contained in $ORACLE_BASE/product/$VERSION/dbs after move" >> $LOGFILE
ls -ltr $ORACLE_BASE/product/${VERSION}/db_1/dbs/*${ORACLE_SID}* >> $LOGFILE

#------------------------------------------------------------
# Configure Network 
#------------------------------------------------------------

if [ -f $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora ] ; then
  cp $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora_bkup_$DATEVAR
else
  cp $ORACLE_HOME/network/admin/listener.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin
fi

echo "Contents of listener.ora prior to update........." >> $LOGFILE
cat $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora >> $LOGFILE

OLD_VERSION=`echo $ORACLE_HOME | cut -d '/' -f7`

sed "s;${OLD_VERSION}/;${VERSION}/;g" $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora >$ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora_new_$DATEVAR
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> listener.ora update Failed"
  exit 1
fi

cp $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora_new_$DATEVAR $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora

log_console " "
echo "Contents of listener.ora after the update........." >> $LOGFILE
cat $ORACLE_BASE/product/$VERSION/db_1/network/admin/listener.ora >> $LOGFILE

if [ -f $ORACLE_BASE/product/$VERSION/db_1/network/admin/tnsnames.ora ] ; then
  cp $ORACLE_BASE/product/$VERSION/db_1/network/admin/tnsnames.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin/tnsnames.ora_bkup_$DATEVAR
fi

cp $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin

if [ -f $ORACLE_BASE/product/$VERSION/db_1/network/admin/sqlnet.ora ] ; then
  cp $ORACLE_BASE/product/$VERSION/db_1/network/admin/sqlnet.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin/sqlnet.ora_bkup_$DATEVAR
fi

cp $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin

if [ -f $ORACLE_BASE/product/$VERSION/db_1/network/admin/ldap.ora ] ; then
  cp $ORACLE_BASE/product/$VERSION/db_1/network/admin/ldap.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin/ldap.ora_bkup_$DATEVAR
fi

cp $ORACLE_HOME/network/admin/ldap.ora $ORACLE_BASE/product/$VERSION/db_1/network/admin
cp $ORACLE_HOME/hs/admin/extproc.ora $ORACLE_BASE/product/$VERSION/db_1/hs/admin/extproc.ora


#---------------------------------------------------------
# Configure  SRVCTL with new release
#---------------------------------------------------------

echo -e "\nsrvctl config prior to update.........." >> $LOGFILE
srvctl config listener -l $ORACLE_SID >> $LOGFILE
srvctl config database -d ${ORACLE_SID}_${SERVER_NAME} >> $LOGFILE

log_console " "
log_console "Updating srvctl configuration.........."
srvctl modify listener -l $ORACLE_SID -oraclehome $ORACLE_BASE/product/$VERSION/db_1 >> $LOGFILE
srvctl modify database -d ${ORACLE_SID}_${SERVER_NAME} -oraclehome $ORACLE_BASE/product/$VERSION/db_1 -spfile  $ORACLE_BASE/product/$VERSION/db_1/dbs/spfile${ORACLE_SID}.ora >> $LOGFILE
srvctl setenv listener -l $ORACLE_SID -env "TNS_ADMIN=$ORACLE_BASE/product/$VERSION/db_1/network/admin" >> $LOGFILE
log_console "Configuratioin update complete"
echo -e "\nsrvctl config after update............." >> $LOGFILE
srvctl config listener -l $ORACLE_SID  >> $LOGFILE
srvctl config database -d ${ORACLE_SID}_${SERVER_NAME} >> $LOGFILE

#---------------------------------------------------------
#  Start database and listener 
#---------------------------------------------------------

#srvctl stop database -d ${ORACLE_SID}_${SERVER_NAME} >> $LOGFILE

srvctl enable listener -l $ORACLE_SID >> $LOGFILE
srvctl start listener -l $ORACLE_SID  >> $LOGFILE
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> srvctl start listener failed!!!"
  exit 1
fi

srvctl start database -d ${ORACLE_SID}_${SERVER_NAME} >> $LOGFILE
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> srvctl start database failed!!!"
  exit 1
fi
 
if [ $ADG = 'true' ]; then
  log_console " "
  log_console "Setting start option back to READ ONLY....."
  srvctl modify database -d ${ORACLE_SID}_${SERVER_NAME} -startoption "READ ONLY"
  log_console "Start option has been set."
fi


#------------------------------------------------------------
# update symbolic link from $ORACLE_BASE/admin/$ORACLE_SID
# to $ORACLE_HOME to suuport Gardium and the viloin agent
#------------------------------------------------------------

if [ -e $ORACLE_BASE/admin/$ORACLE_SID/oracle_home ] ; then
   log_console " "
   log_console "Switching ORACLE_HOME link"
   rm  $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   ln -s $ORACLE_BASE/product/$VERSION/db_1 $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link"
   else
     log_console "Oracle Home symbolic link has been created as the following:"
     ls -l $ORACLE_BASE/admin/$ORACLE_SID/oracle_home | tee -a $LOGFILE
     log_console " "
   fi
else
   log_console " "
   ln -s $ORACLE_BASE/product/$VERSION/db_1 $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link"
   else
     log_console "Oracle Home symbolic link has been created as the following:"
     ls -l $ORACLE_BASE/admin/$ORACLE_SID/oracle_home | tee -a $LOGFILE
     log_console " "
   fi
fi


#---------------------------------------------------------
#  Update OEM 
#--------------------------------------------------------

log_console "Starting OEM update........."
 
 
if [ -x $ORACLE_BASE/product/emcli/emcli ] ; then
  log_console " emcli exists and is executable, updating OEM"
  . oraenv
  export UNIQUE_NAME=$SQLPATH/unique_name_$ORACLE_SID.log
  echo "set echo off ver off pages 0 trims on head off feed off
  select db_unique_name from v\$database ;
  exit;" | sqlplus -s / as sysdba > $UNIQUE_NAME
  export UNIQUE_NAME=$(tail -1 $UNIQUE_NAME |sed -e 's/ //g')

  SYS_DETAILS=`$ORACLE_BASE/product/emcli/emcli  get_db_sys_details_from_dbname -db_unique_name=$UNIQUE_NAME`
  if [ $? -gt 0 ] ; then
    echo "OEM system details could not be retrirved, assume the standby OEM target name is the standby database unique name" | tee -a $LOGFILE
    TARGET_NAME=$UNIQUE_NAME
  else
    TARGET_NAME=`echo $SYS_DETAILS | cut -d : -f1`
  fi

  LSNR_NAME=`$ORACLE_BASE/product/emcli/emcli get_targets -targets="%$ORACLE_SID%$SERVER_NAME%":"oracle_listener" -noheader -format="name:csv" | cut -d , -f4`
  log_console "Oracle Database Home prior to update: `$ORACLE_BASE/product/emcli/emcli  list -resource="TargetProperties" -search="TARGET_TYPE='oracle_database'" -search="TARGET_NAME='$TARGET_NAME'" -search="PROPERTY_NAME='OracleHome'" -columns="PROPERTY_VALUE" -script -noheader`"
  log_console "Oracle Listener Home prior to update: `$ORACLE_BASE/product/emcli/emcli  list -resource="TargetProperties" -search="TARGET_TYPE='oracle_listener'" -search="TARGET_NAME='$LSNR_NAME'" -search="PROPERTY_NAME='OracleHome'" -columns="PROPERTY_VALUE" -script -noheader`"
  log_console " "

  $ORACLE_BASE/product/emcli/emcli modify_target -name="$TARGET_NAME" -type=oracle_database -properties="OracleHome:$ORACLE_HOME" -on_agent >> $LOGFILE
  if [ $? -gt 0 ] ; then
    log_console "OEM Database Target update has failed!!!  Please update OEM with the new ORACLE_HOME value manually"
  else
    log_console "OEM Database Target has been updated with the ORACLE_HOME value of $ORACLE_HOME for database $UNIQUE_NAME"
  fi

  $ORACLE_BASE/product/emcli/emcli modify_target -name="$LSNR_NAME" -type=oracle_listener -properties="OracleHome:$ORACLE_HOME;ListenerOraDir:$ORACLE_HOME/network/admin" -on_agent >> $LOGFILE
  if [ $? -gt 0 ] ; then
    log_console "OEM Listener Target update has failed!!!  Please update OEM with the new ORACLE_HOME value manually"
  else
    log_console "OEM Listener  Target has been updated with the ORACLE_HOME value of $ORACLE_HOME for listener $LSNR_NAME"
  fi

  log_console " "
  log_console "Oracle Database Home after update: `$ORACLE_BASE/product/emcli/emcli  list -resource="TargetProperties" -search="TARGET_TYPE='oracle_database'" -search="TARGET_NAME='$TARGET_NAME'" -search="PROPERTY_NAME='OracleHome'" -columns="PROPERTY_VALUE" -script -noheader`"
  log_console "Oracle Listener Home after update: `$ORACLE_BASE/product/emcli/emcli  list -resource="TargetProperties" -search="TARGET_TYPE='oracle_listener'" -search="TARGET_NAME='$LSNR_NAME'" -search="PROPERTY_NAME='OracleHome'" -columns="PROPERTY_VALUE" -script -noheader`"
else
  log_console "emcli is not installed on this server, please update OEM with the new ORACLE_HOME manually"
fi

log_console " "
log_console "Patching of $ORACLE_SID  to  $VERSION  complete on  `uname -svrn` at `date` using $0 "
exit 0

