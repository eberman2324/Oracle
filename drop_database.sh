#!/bin/bash
################################################################################################################################################
#  drop_database.sh is executed to delete a standard build database   
#
#  usage: $ . drop_database.sh  <db_name>  
#
#
#  Maintenance Log:
#  1.0  03/2018      R. Ryan     New Script 
#  1.1  04/2018      R. Ryan     Modified script to unregister database dataase from recovery catalog, 
#                                reset archivelog deletion policy on primary if dropping last standby.
#  1.2  05/2018      R. Ryan     Modified script to remove the dataguard configuration if the last standby is being dropped
#                                Modified script to construct a tns connect string for the primary database rather than relying on tnsnames.ora
#  1.3  06/2018      R. Ryan     Modified script to enable log transport when there are remaining standby databases.
#  2.0  01/2019      R. Ryan     18c Support. DBCA now requires sysman password when dropping a database.
#  3.0  01/2019      R. Ryan     Added support for active dataguard standby databases.
#  3.1  07/2019      R. Ryan     Accounted bore multyple drops of the same ddatabase when cleaning up tsm/rman.
#  3.2  09/2019      R. Ryan     Provided the ability to schedule the rman/tsm backup cleanup job up to 90 days from the drop.
#  4.0  01/2020      R. Ryan     Extended support to container databases
#  4.1  01/2020      R. Ryan     Prevent the removal of $DBS files when Oracle SID names are very similar.
#  4.2  10/2020      R. Ryan     Set the RCATPASS variable since it was removed from oraenv
#  5.0  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#  5.1  11/2022      R. Ryan     Modified script for BT
#  5.2  04/2023      R. Ryan     remove cleanup of admin directory
#
################################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Function : Start database in read only mode
start_database () {
sqlplus -S /nolog <<EOF  >>$LOGFILE
whenever sqlerror exit 1
connect / as sysdba
startup mount;
alter system set dg_broker_start=false;
alter database open read only;
exit;
EOF

if [ $? -gt 0 ] ; then
  log_console "Database startup in read only mode failed, please remove database manually"
  exit 1
else
  log_console "Database ${ORACLE_SID}_${SERVER_NAME} has been started and opened read only....."
fi
}

# Function : Prep Physical Standby Database for drop
prep_standby_database () {

#-----------------------------------------------------------
# Get Primary database unique name
#-----------------------------------------------------------
PRIMARY_DB=(`sqlplus -s / as sysdba<<eof1
@get_primary_database.sql
eof1`)
if [ $? -gt 0 ]; then
  log_console "Primary Database name fetch failed.....please ensure the database is avaialble"
  exit 1
fi

export PORT=`srvctl config listener -l $ORACLE_SID | grep TCP | cut -d : -f3 | cut -d / -f1`
export PRIM_HOST=`echo $PRIMARY_DB | cut -d _ -f2`
export PRIM_CONN=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${PRIM_HOST})(PORT=${PORT}))(CONNECT_DATA=(SID=${ORACLE_SID})))"'"'`

#-------------------------------------------------------------
# Propet for sys password, required to set primary archivelog
# delete policy
#-------------------------------------------------------------
#unset password
#prompt="enter sys password:"
#
#    while IFS= read -p "$prompt" -r -s -n 1 char
#            do
#                    if [[ $char == $'\0' ]]
#                            then
#                                    break
#                    fi
#                    prompt='*'
#                    password+="$char"
#            done
#
#log_console " "
#
#
#sqlplus -S sys/$password@${PRIM_CONN} as sysdba<<eof1 >> $LOGFILE
#whenever sqlerror exit 1
#exit;
#eof1
#
#if [ $? -gt 0 ]; then
#  log_console "Invalid Password, try again"
#  exit 1
#else
#  log_console "Log on successful, continuing with drop....."
#  log_console " "
#fi


#-----------------------------------------------------------
# Disable Log Shipping
#-----------------------------------------------------------

if [ -z "$PRIMARY_DB" ] ; then
  log_console "Primary database no longer exist or cannot be identified, skipping log transport disable....."
else
  log_console "Disabling log transport on ${PRIMARY_DB}....."
  dgmgrl -echo / "edit database '${PRIMARY_DB}' set state=transport-off" | tee -a $LOGFILE
  if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
    log_console "Log transport disable failed"
    exit 1
  else
    log_console "Log transport has been disabled on $PRIMARY_DB"
  fi
fi

#-----------------------------------------------------------
# Get standby database count
#-----------------------------------------------------------

export STANDBY_COUNT=$LOGDIR/standby_count_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(*) from v\$DATAGUARD_CONFIG where dest_role<>'PRIMARY DATABASE';
exit;" | sqlplus -s sys/${password}@${PRIM_CONN} as sysdba > $STANDBY_COUNT

export STANDBY_COUNT=$(tail -1 $STANDBY_COUNT |sed -e 's/ //g')


#---------------------------------------------------------
# Stop Log apply
#---------------------------------------------------------
log_console "Disabling log apply on ${ORACLE_SID}_${SERVER_NAME} ........"
dgmgrl -echo / "edit database '${ORACLE_SID}_${SERVER_NAME}' set state='APPLY-OFF';" | tee -a $LOGFILE 
if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "Log  apply disable failed"
  exit 1
else
  log_console "Log apply  has been disabled on ${ORACLE_SID}_${SERVER_NAME}"
fi

#----------------------------------------------------------
# Remove Standby from DG config
#----------------------------------------------------------
dgmgrl -echo / "remove  database '${ORACLE_SID}_${SERVER_NAME}'" | tee -a $LOGFILE
if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "Removal of database from DG config failed"
  exit 1
else
  log_console "${ORACLE_SID}_${SERVER_NAME} has been removed from DG config"
fi

if [ $STANDBY_COUNT -eq 1 ] ; then
  log_console " "
  log_console "Dropping only standby in the DG configuration, removing the DG configuration......."
  dgmgrl -echo sys/${password}@${PRIM_CONN} "remove  configuration" | tee -a $LOGFILE
  log_console " "
  log_console "Stopping DG broker on primary database....."
  echo "alter system set dg_broker_start=false;
exit;" | sqlplus -s sys/${password}@${PRIM_CONN} as sysdba | tee -a $LOGFILE
  log_console "DG broker has been stopped on primary database"
else
  log_console " "
  log_console "Enabling log transport on $PRIMARY_DB....."
  dgmgrl -echo sys/${password}@${PRIM_CONN} "edit database '${PRIMARY_DB}' set state=transport-on" | tee -a $LOGFILE
  if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
    log_console "Log transport enable failed on $PRIMARY_DB"
    log_console "Please enable log transport manually"
  else
    log_console "Log transport has been enabled on $PRIMARY_DB"
  fi
fi

#---------------------------------------------------------
# Open database read only and drop database
#---------------------------------------------------------
srvctl config database -d ${ORACLE_SID}_${SERVER_NAME} | grep 'read only'
if [ $? -eq 0 ]; then
  ADG=true
  log_console " "
  log_console "Standby database is configured with Active Dataguard, bouncing database to ensure it is read only......"
  srvctl stop database -d ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
  srvctl start database -d ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
else
  ADG=false
  sqlplus -S /nolog <<EOF  >>$LOGFILE
  whenever sqlerror exit 1
  connect / as sysdba
  alter database open read only;
  exit;
EOF
fi

if [ $? -gt 0 ] ; then
  log_console "Open of standby database in read only mode failed"
  exit 1
else
  log_console "Standby Database ${ORACLE_SID}_${SERVER_NAME} has been opened read only....."
fi
}

remove_oem_targets () {
#----------------------------------------------------------
#  Remove  database from OEM
#----------------------------------------------------------
log_console " "
log_console "Starting OEM update........."

#if [ -d /usr/java ]; then
#  export JAVA_HOME=/usr/java/default
#else
#  export JAVA_HOME=$ORACLE_HOME/jdk
#fi

if [ -x $ORACLE_BASE/product/emcli/emcli ] ; then
  log_console " emcli exists and is executable, updating OEM"
  $ORACLE_BASE/product/emcli/emcli delete_target -name="${DB_NAME}_${SERVER_NAME}" -type="oracle_database"
  case $? in
    [1-5]|[7-23]|[219-223]*) log_console "OEM Database Target delete has failed!!!  Please remove standby database from OEM manually" ;;
    6) log_console "Database target does not exist in OEM" ;;
    *) log_console "OEM Database Target has been deleted";;
  esac

  if [[ $ORACLE_SID != CDB[0-9][0-9]C ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
    $ORACLE_BASE/product/emcli/emcli delete_target -name="${DB_NAME}_${HOSTNAME}" -type="oracle_listener"
    case $? in
      [1-5]|[7-23]|[219-223]*) log_console "OEM Listener Target delete has failed!!!  Please remove listener from OEM manually" ;;
      6) log_console "Listener target does not exist in OEM" ;;
      *) log_console "OEM Listener  Target has been deleted";;
    esac
  fi
else
  log_console "emcli is not installed on this server, please add database to OEM manually"
fi
}

schedule_backup_cleanup () {

log_console " "
log_console "Scheduling RMAN/TSM cleanup Job in OEM"


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

ORACLEDBAPASS=`fetch_db_bt.bash.x -a DBA -r "create standby database" -P oracledba -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`


read -p "enter the number of days up to 90 from today you would like the cleanup to execute: " days
echo $days
if [ -n "$days" ] && [ "$days" -eq "$days" ] 2>/dev/null; then
 days=$days
else
 days=100
fi
while  [[ "$days" -gt "90" ]]
do
  read -p "invalid number, enter the number of days up to 90 from today you would like the cleanup to execute: " days
  if [ -n "$days" ] && [ "$days" -eq "$days" ] 2>/dev/null; then
    days=$days
  else
    days=100
  fi
done

RUN_DATE=$(date +'%F' -d "+${days} days")

echo target_list=${HOSTNAME}:host > /tmp/job_prop_$DB_NAME.txt
echo schedule.startTime=${RUN_DATE} 05:00:00 >> /tmp/job_prop_$DB_NAME.txt
echo schedule.frequency=ONCE >> /tmp/job_prop_$DB_NAME.txt
echo cred.defaultHostCred.${HOSTNAME}:host=NAMED:SYSMAN:SSH_ORACLE_CREDENTIALS >> /tmp/job_prop_$DB_NAME.txt
echo variable.default_shell_command=$SCRIPTS/cleanup_rman_tsm.sh ${DB_NAME}_del_${DATEVAR} ${DB_ID} >> /tmp/job_prop_$DB_NAME.txt

$EMCLI logout | tee -a $LOGFILE
$EMCLI login  -username=oracledba -password=$ORACLEDBAPASS | tee -a $LOGFILE

$EMCLI create_job  -name=CLEANUP_RMAN_TSM_${DB_NAME}_${SERVER_NAME}_${DATEVAR} -type=OSCommand -input_file=property_file:/tmp/job_prop_${DB_NAME}.txt | tee -a $LOGFILE

if [ $? -gt 0 ] ; then
  log_console "Cleanup RMAN/TSM job scheduling failed for ${DB_NAME},  Please schedule Job manually"
else
  log_console "Cleanup RMAN/TSM job has been scheduled for ${DB_NAME}."
fi

$EMCLI logout | tee -a $LOGFILE
rm /tmp/job_prop_$DB_NAME.txt
log_console " "
}

backup_archive_logs () {

rman target / catalog $RCAT/`echo $RCATPASS`@$RCATDB <<EOF >>$LOGFILE
crosscheck archivelog all;
backup archivelog all delete input;
quit
EOF

if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Archive log backup failed, do you wish to continue?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) log_console "User replies Yes, continuing with drop....."
              break;;
        No ) log_console "User replies No, no action taken"
             exit;;
    esac
  done
else
   log_console "Archivelog backup successful"
fi
log_console " "
}

drop_archive_logs () {

rman target / catalog $RCAT/`echo $RCATPASS`@$RCATDB <<EOF >>$LOGFILE
crosscheck archivelog all;
delete force noprompt archivelog all;
quit
EOF

if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Archive log drop failed, do you wish to continue?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) log_console "User replies Yes, continuing with drop....."
              break;;
        No ) log_console "User replies No, no action taken"
             exit;;
    esac
  done
else
   log_console "Archivelog drop successful"
fi
log_console " "
}


#End of functions

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/drop_db_$1_$DATEVAR.out
EMCLI=${STD_DBMS_DIR}/app/oracle/product/emcli/emcli
. ~/.bash_profile >/dev/null 2>&1

cd ~

if [ $# -ne 1 ]; then
  log_console "Usage: $0  target_db_name "
  log_console Parms: $*
  exit 1
fi

log_console "Start drop database $1  `uname -svrn` at `date` using $0 $*"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

export ORACLE_SID=$1
ORATAB=/etc/oratab
#grep $ORACLE_SID $ORATAB | grep -v $ORACLE_SID[0-z] | grep -v ${ORACLE_SID}_del >/dev/null 2>&1
grep $ORACLE_SID $ORATAB | grep -v ${ORACLE_SID}_del >/dev/null 2>&1
if [ $? -gt 0 ]; then
  log_console "Database is not present in ORATAB, make sure $ORACLE_SID is a valid database"
  exit 1
fi

shopt -s expand_aliases
export ORAENV_ASK=NO
. oraenv >> $LOGFILE
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`
if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
  RCAT=$SERVER_NAME
else
  RCAT=$ORACLE_SID
fi

RCATPASS=`rcatpass`

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep >/dev/null
if test $? -ne 0; then
  ps -ef | grep pmon_$1$ | grep -v grep >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active. Attempting to start in read only mode"
  start_database 
fi


#-------------------------------------------------------------
# Propet for sys password, required to set primary archivelog
# delete policy
#-------------------------------------------------------------
log_console " "
unset password
prompt="enter sys password:"

    while IFS= read -p "$prompt" -r -s -n 1 char
            do
                    if [[ $char == $'\0' ]]
                            then
                                    break
                    fi
                    prompt='*'
                    password+="$char"
            done

log_console " "

sqlplus -S sys/${password}@${ORACLE_SID}_${SERVER_NAME} as sysdba<<eof1 >> $LOGFILE
whenever sqlerror exit 1
exit;
eof1

if [ $? -gt 0 ]; then
  log_console "Invalid Password, try again"
  exit 1
else
  log_console "Log on successful, continuing with drop....."
  log_console " "
fi


#------------------------------------------------------------------------
#  Check Database Role
#------------------------------------------------------------------------
DB_ROLE=(`sqlplus -s / as sysdba<<eof1
@get_database_role.sql 
eof1`)
if [ $? -gt 0 ]; then
  log_console "Database Role Check Failed.....please ensure the database is avaialble"
  exit 1
fi

if [ "$DB_ROLE" = "PHYSICALSTANDBY" ] ; then
  log_console "Database has been identified as a physical standby database, dropping physical standby......"
  prep_standby_database
else
  log_console "Do you wish to backup remaining archive logs before dropping database?"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) log_console "User replies Yes, backing up archive logs please wait....."
              log_console "Review log $LOGFILE in another session to see backup progress"
              backup_archive_logs 
              break;;
        No ) log_console "User replies No, dropping archive logs....."
              drop_archive_logs 
              break;;
    esac
  done
fi

#------------------------------------------------------------------------
# Fetch DBID
#------------------------------------------------------------------------
DB_ID=(`sqlplus -s / as sysdba<<eof1
@get_database_dbid.sql
eof1`)
if [ $? -gt 0 ]; then
  log_console "Database DBID fetch  Failed.....please ensure the database is avaialble"
  exit 1
else
  log_console "The DBID for ${ORACLE_SID}_${SERVER_NAME} is ${DB_ID}"

fi

log_console " "
log_console "About to drop database ${ORACLE_SID}_${SERVER_NAME} are you sure you want to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) log_console "User replies Yes, continuing with drop....."
              break;;
        No ) log_console "User replies No, no action taken"
             exit;;
    esac
done
log_console " "



#------------------------------------------------------------------------
#  Drop Database
#------------------------------------------------------------------------
log_console "Dropping Database ..................."
dbca -silent -deleteDatabase -sourceDB $ORACLE_SID -sysPassword $password | tee -a $LOGFILE
log_console "Drop of database $ORACLE_SID complete"
log_console " "
log_console "Removing listener $ORACLE_SID........"
srvctl stop listener -l $ORACLE_SID | tee -a $LOGFILE
srvctl remove listener -l $ORACLE_SID | tee -a $LOGFILE
log_console "Listener $ORACLE_SID has been removed"
log_console " "

#-----------------------------------------------------------------------
# Remove dbs files,  and diag directories
#----------------------------------------------------------------------
rm -f $ORACLE_HOME/dbs/*${ORACLE_SID}[._]* | tee -a $LOGFILE
rm -f $ORACLE_HOME/dbs/*${ORACLE_SID} | tee -a $LOGFILE
log_console "Do you want to save and remove the database and listener diag directories?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) log_console "Saving database and listener diag directories...." 
              listener_name=`echo $ORACLE_SID | tr '[:upper:]' '[:lower:]'`
              tar cf - $ORACLE_BASE/diag/rdbms/$DB_UNIQUE_NAME/$ORACLE_SID | zip $ORACLE_BASE/local/logs/${DB_UNIQUE_NAME}_dbms_diag.$DATEVAR.zip - >/dev/null 2>$1
              tar cf - $ORACLE_BASE/diag/tnslsnr/$SERVER_NAME/$listener_name | zip $ORACLE_BASE/local/logs/${listener_name}_tnslsnr_diag.$DATEVAR.zip - >/dev/null 2>$1
              log_console "Save Complete, dropping database and listener diag...."
              rm -rf $ORACLE_BASE/diag/rdbms/$DB_UNIQUE_NAME/$ORACLE_SID
              rm -rf $ORACLE_BASE/diag/tnslsnr/$SERVER_NAME/$listener_name
              log_console "Diag directory removal complete"
              log_console " "
              break;;
        No ) log_console "User Replies NO, keeping diag directories. "
             log_console " "
             break;;
    esac
done

if [ -f $STD_STAGE_DIR/oracle_setup_status_create_${ORACLE_SID}_successful ]; then
  rm -f $STD_STAGE_DIR/oracle_setup_status_create_${ORACLE_SID}_successful
fi

#-------------------------------------------------------------------
# Remove database admin directory
#-------------------------------------------------------------------
#log_console "Do you want to save and remove the $ORACLE_BASE/admin/${ORACLE_SID} directory?"
#select yn in "Yes" "No"; do
#    case $yn in
#        Yes ) log_console "Saving $ORACLE_BASE/admin/${ORACLE_SID} in $ORACLE_BASE/local/logs"
#              tar cf - $ORACLE_BASE/admin/$ORACLE_SID | zip $ORACLE_BASE/local/logs/${ORACLE_SID}_admin_dir.$DATEVAR.zip - >/dev/null 2>$1 
#              rm -r $ORACLE_BASE/admin/$ORACLE_SID
#              log_console "admin directory has been saved are removed."
#              log_console " "
#              break;;
#        No ) log_console "User Replies NO, keeping admin directory, removing ORACLE_HOME symbolic link"
#             rm $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
#             log_console "oracle_home symbolic link has been removed"
#             log_console " "
#             break;;
#    esac
#done

#-------------------------------------------------------------------------
# Reset Primary database archivelog purge policy/unregister db_unique_name
#------------------------------------------------------------------------
if [ "${DB_ROLE}" =  "PHYSICALSTANDBY" ] ; then
  if [ $STANDBY_COUNT -eq 1 ] ; then
    log_console " "
    log_console "Resetting Primary database archivelog deletion policy......."
    rman target sys/${password}@${PRIM_CONN} catalog $RCAT/`echo $RCATPASS`@$RCATDB <<EOF >>$LOGFILE
    configure ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES to 'SBT_TAPE'; 
    quit
EOF
    if [ $? -gt 0 ]; then
       log_console "Primary database archivelog deletion policy update failed, please update the poilcy manually."
    else
       log_console "Primary database archivelog deletion policy has been updated."
    fi
  fi
 log_console " "
 log_console "Unregistering DB UNIQUE NAME ${ORACLE_SID}_${SERVER_NAME} for DBID $DB_ID from recovery catalog......."
 rman  catalog $RCAT/`echo $RCATPASS`@$RCATDB <<EOF >>$LOGFILE
 set dbid $DB_ID;
 unregister db_unique_name ${ORACLE_SID}_${SERVER_NAME} noprompt;
EOF
 if [ $? -gt 0 ]; then
   log_console "Unregistering DB_UNIQUE_NAME failed, please update unregister ${ORACLE_SID}_${SERVER_NAME} for DBID $DB_ID manually."
 else
   log_console "Unregistering DB_UNIQUE_NAME ${ORACLE_SID}_${SERVER_NAME} for DBID $DB_ID is successful."
 fi
 log_console " "
fi

#-------------------------------------------------------------------
# Remove ASM directories
#-------------------------------------------------------------------
#log_console "Removing ASM directories.........."
DB_HOME=$ORACLE_HOME
DB_NAME=$ORACLE_SID
#export ORACLE_SID=+ASM
#export ORAENV_ASK=NO
#. oraenv >> $LOGFILE
#asmcmd rm -r */${DB_NAME}_${SERVER_NAME}
#if [ $? -gt 0 ]; then
#  log_console "ASM directory removal failed"
#else
# srvctl remove database -d ${DB_NAME}_${SERVER_NAME} -noprompt
#  log_console "ASM directory removal is commplete"
#fi
#log_console " "


#-------------------------------------------------------------------
# Remove database and linstener targets from OEM
#-------------------------------------------------------------------
log_console "Do you want to remove the OEM database and listener targets?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) remove_oem_targets
              break;;
        No ) log_console "User Replies NO, OEM will not be updated"
             break;;
    esac
done
log_console " "

#-----------------------------------------------------------------
# Drop Backups
#-----------------------------------------------------------------
if [ "${DB_ROLE}" !=  "PHYSICALSTANDBY" ] ; then
  log_console "Do you want to delete database backups?"
  select yn in "Yes" "No" "Schedule"; do
      case $yn in
         Yes ) log_console "Deleting backups for ${DB_NAME} dbid ${DB_ID} ........."
               mkdir -p $ORACLE_BASE/admin/$ORACLE_SID
               ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
               grep TSTDB12_del /etc/oratab > /dev/null
               if [ $? -gt 0 ]; then
                  echo ${DB_NAME}_del_${DATEVAR}:$DB_HOME:N '  # Place Holder for backup cleanup. DO NOT REMOVE'  >> /etc/oratab
               fi
               cleanup_rman_tsm.sh ${DB_NAME}_del_${DATEVAR} ${DB_ID} | tee -a $LOGFILE
               break;;
          No ) log_console "User Replies NO, no cleanup actions will be taken"
               break;;
    Schedule ) log_console "Scheduling backup cleanup job in OEM for ${DB_NAME} dbid ${DB_ID} "
               mkdir -p $ORACLE_BASE/admin/$ORACLE_SID
               ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
               grep TSTDB12_del /etc/oratab > /dev/null
               if [ $? -gt 0 ]; then
                  echo ${DB_NAME}_del_${DATEVAR}:$DB_HOME:N '  # Place Holder for backup cleanup. DO NOT REMOVE'  >> /etc/oratab
               fi
               schedule_backup_cleanup
               break;;
      esac
  done
fi

log_console " "

log_console ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>R E M I N D E R<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
log_console "Please review and complete the following items if applicable to this database drop activity:"
log_console "1. Please remove any obsolete ICR entries."
log_console "2. Please request any managed accounts for this database to be removed from BT."
log_console "3. Please remove any non-managed accounts for this database from BT."
log_console " "

log_console "Drop  $1 complete  `uname -svrn` at `date` using $0 "
echo 


exit 0

