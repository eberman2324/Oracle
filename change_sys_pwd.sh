#!/bin/bash
#######################################################################################################################################
#  patch_db.sh is executed to change the sys password in dataguard database environments.
#
#  usage: $ . change_sys_password.sh   <target_db_name>  
#
#
#  Maintenance Log:
#  version 1.0 05/18/2016      R. Ryan     New Script 
#  version 1.1 10/06/2016      R. Ryan     Corrected instance active check 
#  version 1.2 10/25/2016      R. Ryan     changed edmz url to pum 
#  version 1.3 11/14/2016      R. Ryan     added sourcing of bash_profile to avoid JAVA_HOME issues with emcli 
#  version 1.4 01/17/2018      R. Ryan     corrected issue with muliple standby databases. 
#  version 1.5 05/07/2018      R. Ryan     Modified script to attempt an add of the acccount to tpam to ensure it exists in tpam 
#  version 1.6 04/24/2019      R. Ryan     Added sleep for 30 seconds after blackout creation. 
#  version 1.7 02/06/2020      R. Ryan     Set monitoring credentials to dbsnmp for ADG standby databases 
#  version 2.0 01/19/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#  version 2.1 08/12/2021      R. Ryan     Modified script to stop and remove blackouts from failed executions
#
######################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

get_cred_user () {
CON_DESC=`dgmgrl -echo / "show  database '$1' DGConnectIdentifier" | grep "DGConnectIdentifier =" | cut -d "'" -f2`
OPEN_MODE=(`sqlplus -s sys/$PASSWD@$CON_DESC as sysdba <<EOF
whenever sqlerror exit failure;
@get_open_mode.sql
EOF`)

case $OPEN_MODE in
  MOUNTED)
    CRED_USER=SYS
    CRED_PASS=$PASSWD
    CRED_ROLE=SYSDBA
  ;;
  READ)
    CRED_USER=DBSNMP
    CRED_PASS=drugs2gogo
    CRED_ROLE=NORMAL
  ;;
  *)
    log_console "Failed to fetch standby database open mode"
    exit 1
  ;;
esac

}


 
#end of functions  

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/change_sys_password_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 1 ]; then
  log_console "Usage: $0  target_db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start SYS password change for db $1 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] 
if test $? -eq 1; then
  ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active...start it before attempting patch"
  exit 1
fi
log_console " "

export ORACLE_SID=$1
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`


#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

log_console ' '
export ORAENV_ASK=NO
. oraenv >> $LOGFILE
export PATH=$PATH:$ORACLE_BASE/product/emcli



#------------------------------------------------------------
#   Check for Standby databases
#------------------------------------------------------------
export STANDBY_COUNT=$SQLPATH/standby_count_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(*) from v\$DATAGUARD_CONFIG where dest_role='PHYSICAL STANDBY';
exit;" | sqlplus -s / as sysdba > $STANDBY_COUNT

export STANDBY_COUNT=$(tail -1 $STANDBY_COUNT |sed -e 's/ //g')

if [ $STANDBY_COUNT -eq 0 ] ; then
 log_console "This database is not configured with Data Guard or log_transport has been disabled for all standby's"
 log_console "SYS passwords for non-dataguard databases should be TPAM managed accounts"
 exit 1
else
 log_console "This database has $STANDBY_COUNT standby database(s)"
 export STANDBY_SERVERS=$SQLPATH/standby_servers_$ORACLE_SID.log
 echo "set echo off ver off pages 0 trims on head off feed off
 select listagg(db_unique_name,'_') within group (order by db_unique_name) names from v\$DATAGUARD_CONFIG where dest_role='PHYSICAL STANDBY';
 exit;" | sqlplus -s / as sysdba > $STANDBY_SERVERS
 export STANDBY_DBS=$SQLPATH/standby_dbs_$ORACLE_SID.log
 echo "set echo off ver off pages 0 trims on head off feed off
 select listagg(db_unique_name,' ') within group (order by db_unique_name) names from v\$DATAGUARD_CONFIG where dest_role='PHYSICAL STANDBY';
 exit;" | sqlplus -s / as sysdba > $STANDBY_DBS

 export STANDBY_DBS=$(tail -1 $STANDBY_DBS)
 export STANDBY_SERVERS=$(tail -1 $STANDBY_SERVERS |sed -e 's/ //g'| cut -d _ -f2,4 | tr '_' ' ')
 
 for SERVER in  $STANDBY_SERVERS
  do
    ssh -o "PasswordAuthentication no" $SERVER 'exit' 2>>$LOGFILE
    if [ $? -ne 0 ] ; then
      log_console "SSH equivalence is not establish for $SERVER"
      log_console "Please ensure SSH keys are present on all standby servers before retrying the SYS password change"
      log_console " "
      exit 1
    fi
  done
fi

#-----------------------------------------------------------
#  End Backouts of previous job failures
#-----------------------------------------------------------

emcli stop_blackout -name="${ORACLE_SID}_${SERVER_NAME}_sys_password_change" > /dev/null 2>&1
sleep 30
emcli delete_blackout -name="${ORACLE_SID}_${SERVER_NAME}_sys_password_change" > /dev/null 2>&1

for SERVER in $STANDBY_SERVERS
  do
    emcli stop_blackout -name="${ORACLE_SID}_${SERVER}_sys_password_change" > /dev/null 2>&1
    sleep 30
    emcli delete_blackout -name="${ORACLE_SID}_${SERVER}_sys_password_change" > /dev/null 2>&1
  done


#--------------------------------------------------------
#   Blackout Primary and Standby Hosts
#--------------------------------------------------------
emcli create_blackout -name="${ORACLE_SID}_${SERVER_NAME}_sys_password_change" -add_targets="${ORACLE_SID}_${SERVER_NAME}:oracle_database"  -schedule="frequency:once;duration:1" -reason="password change"
if [ $? -ne 0 ] ; then
  log_console "Blackout Creation Fail for primary server $HOSTNAME"
  exit 1
fi


for SERVER in $STANDBY_SERVERS
  do
    emcli create_blackout -name="${ORACLE_SID}_${SERVER}_sys_password_change" -add_targets="${ORACLE_SID}_${SERVER}:oracle_database" -schedule="frequency:once;duration:1" -reason="password change"
    if [ $? -ne 0 ] ; then
      log_console "Blackout Creation Fail for standby server ${SERVER}.aetna.com"
      exit 1
    fi
  done

sleep 60

#---------------------------------------------------------
#   Generate and change sys password 
#---------------------------------------------------------
PASSWD=(`sqlplus -s / as sysdba<<eof1
set pages 0
set head off
set feed off
whenever sqlerror exit 1
select randompass from dual;
exit;
eof1`)

if [ $? -ne 0 ] ; then
  log_console "Random Password Generateion Failed"
  log_console " "
  exit 1
fi

sqlplus -s / as sysdba<<eof1
whenever sqlerror exit 1
alter user sys identified by "$PASSWD";
exit;
eof1

if [ $? -ne 0 ] ; then
  log_console "SYS password change failed"
  log_console " "
  exit 1
fi

#--------------------------------------------------------
#  Backup and update Standby Password Files
#--------------------------------------------------------
for SERVER in $STANDBY_SERVERS
  do
    ssh $SERVER "cp ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ${ORACLE_HOME}/dbs/orapw${ORACLE_SID}_bkup_for_pw_change_${DATEVAR}" 
    if [ $? -ne 0 ] ; then
      log_console "Password file backup failed on $SERVER"
      log_console " "
      exit 1
    else
      log_console "Password file backup complete on $SERVER"
    fi
   
    scp ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ${SERVER}:${ORACLE_HOME}/dbs
    if [ $? -ne 0 ] ; then
      log_console "Standby password file update failed on $SERVER"
      log_console " "
      exit 1
    else 
      log_console "Password file update complete on $SERVER"
    fi
  done


#---------------------------------------------------------
#  Update OEM  Standby Database Monitoring Password
#--------------------------------------------------------

for STANDBY_DB in $STANDBY_DBS
  do
    get_cred_user $STANDBY_DB
    emcli set_monitoring_credential -target_name=$STANDBY_DB -target_type=oracle_database -cred_type=DBCreds -set_name=DBCredsMonitoring -attributes="DBUserName:${CRED_USER};DBRole:${CRED_ROLE};DBPassword:${CRED_PASS}"
    if [ $? -ne 0 ] ; then
      log_console "OEM monitoring password update failed for $STANDBY_DB"
      log_console " "
      exit 1
    fi
  done

log_console " "
log_console "Starting OEM update........."
 

#-----------------------------------------------------------
#  End Backouts
#-----------------------------------------------------------

emcli stop_blackout -name="${ORACLE_SID}_${SERVER_NAME}_sys_password_change"
sleep 30
emcli delete_blackout -name="${ORACLE_SID}_${SERVER_NAME}_sys_password_change"
if [ $? -ne 0 ] ; then
   log_console "End Blackout Failed for server ${SERVER_NAME}.aetna.com"
   exit 1
fi

for SERVER in $STANDBY_SERVERS
  do
    emcli stop_blackout -name="${ORACLE_SID}_${SERVER}_sys_password_change"
    sleep 30
    emcli delete_blackout -name="${ORACLE_SID}_${SERVER}_sys_password_change"
    if [ $? -ne 0 ] ; then
      log_console "End Blackout Failed for standby server ${SERVER}.aetna.com"
      exit 1
    fi
  done




#-----------------------------------------------------------
#   Update TPAM
#-----------------------------------------------------------
log_console "Attempting an add of the account in case it does not exist in TPAM"
ssh -i ~/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com AddAccount --AccountName ${SERVER_NAME}_${ORACLE_SID}_SYS --SystemName NMA_Oracle  --password "${PASSWD}"

log_console "Updating password in TPAM"
ssh -i ~/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com UpdateAccount --AccountName ${SERVER_NAME}_${ORACLE_SID}_SYS --SystemName NMA_Oracle  --password "${PASSWD}"
if [ $? -ne 0 ] ; then
   log_console "TPAM password update failed for ${SERVER_NAME}_${ORACLE_SID}_SYS"
   exit 1
else
   log_console "TPAM password update complete"
fi

log_console " "
log_console "End SYS password change for db $1 on  `uname -svrn` at `date` using $0"
exit 0

