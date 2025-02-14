#!/bin/bash
#################################################################################################################################
#
#  usage: $ . create_standby_db.sh   <target_db_sid>  <target_db_port> <primary_host>
#
#   Use the following technique to execute the script in background
#
#         nohup create_standby_db.sh TSTDB12 1530 xorangw1d  <<< $'<number of channels>\n<SYS password>\n' &
#
#  For example:
#         nohup create_standby_db.sh TSTDB12 1530 xorangw1d  <<< $'4\nlocked99999\n' &
#
#         where 4 is the number of channels and locked99999 is the sys password.

#
#
#  Maintenance Log:
#  version 1.0 08/2015      R. Ryan     New Script 
#  Version 1.1 12/2015      R. Ryan     Added prompt for sys password
#                                       Added check for existing DGMGRL configuration (can now add multiple standby databases) 
#                                       Fixed issue with static connect idetifier usig ipc instead of tcp
#                                       Added check for huge pages.
#  Version 1.2 12/2015      R.Ryan      Added database and listener add to OEM
#                                       Removed dbms_version from inputs.  Version is now fetched from thr primary database
#  Version 1.3 02/24/2016   R.Ryan      Check for all DG in primary database
#                                       Corrected version check with new PSU naming
#  Version 1.4 03/11/2016   R. Ryan     Fixed issue with using generic source password
#  Version 1.5 03/18/2016   R. Ryan     Removed Refrences to REDOC_01 and IND_01 disk groups
#                                       modified to create 1 more standby log group than redo log groups
#  Version 1.6 03/31/2016   R. Ryan     Corrected oracle_home symbolic link creation logic
#  Version 1.7 05/23/2016   R. Ryan     Modified the DG broker set up to set the Operation Time Out to 120.
#  Version 1.8 08/19/2016   R. Ryan     Create 3 control files to conform to stadard.  Plase 3rd control file in REDOC_1 if it exeists
#                                       and in FLASH if it does not. 
#  Version 1.9 09/27/2016   R. Ryan     added sqlpath assignment to avoid environmental issues, moved log files to the logs dir.
#  Version 2.0 09/27/2016   R. Ryan     corrected active database check
#  Version 2.1 11/14/2016   R. Ryan     sourced bash_profile to avoid sqlpath, java_home and rcatdb issues.
#  Version 2.2 01/26/2017   R. Ryan     Added scheduling of log purge job in OEM
#  Version 2.3 03/13/2017   R. Ryan     Modified ORACLEDBA_SYSATEM variable due to EMCLDPRD database move to xoraclddbm1p
#  Version 2.3 03/24/2017   R. Ryan     Added "Standard Build Comment"  in OEM
#  Version 3.0 12/01/2017   R. Ryan     Added EBS support, scheduled archive log purge jobs, scheduled sys password change
#  Version 3.1 02/07/2018   R. Ryan     Added support to migrate from non-nextgen linux to nextgen linux.
#  Version 3.2 03/26/2018   R. Ryan     Removed the node name from the change sys password and purge standby log jobs
#                                       Made change to ignore dummy ORATAB entry using in RMAN/TSM cleanup
#                                       Prevneted duplicate listner.ora and tnsnames.ora entries from being created
#                                       Added check for source database in archivelog mode
#  Version 3.3 04/02/2018   R. Ryan     Corrected issue with standard build comment introducced with release 3.2
#  Version 3.4 04/05/2018   R. Ryan     Modified script to connect to recovery catalog when setting archivelog delete policy.
#  Version 3.5 06/01/2018   R. Ryan     Modified script to avoid stanby log pugre job collisions
#  Version 3.6 06/21/2018   R. Ryan     Modified script to convert a primary host name input in upper case to lower case.
#  Version 4.0 01/14/2018   R. Ryan     Modified script to support 18c changes.
#  Version 4.1 10/07/2019   R. Ryan     Added OEM contact assignment for both database and listener for Data Center paging.
#  Version 5.0 03/02/2020   R. Ryan     Corrected issue with 18c and above starting an auxiliary database with default SGA size.
#                                       Added support for container databases
#  Version 5.1 03/23/2020   R. Ryan     Added thread assignmet to standbty redo log creation to avoid default thread 0 issue 
#                                       introduced with version 12.2.
#  Version 5.2 10/30/2020   R. Ryan     Set the RCATPASS variable since it was removed from oraenv 
#  Version 6.0 01/19/2021   R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#  Version 6.1 03/04/2021   R. Ryan     Added section size to support big file tablespaces
#  Version 6.2 04/21/2021   R. Ryan     Connect internal to the standby rathen than via network when setting file managment to automation to avoid locked sys account isses.
#
################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Function : Check DG space

check_data_dg () {

space_needed=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_space_required.sql $1
eof1`)
if [ $? -gt 0 ]; then
  log_console "Required space check failed, make sure source database at $SOURCE_DB is available."
  exit 1
fi

DG1=`echo $1 | tr -d +`
freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'$DG1'"
eof1`)

if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi
if [ "${freespace[0]}" = "1"  ]; then
  log_console "Disk Group $DG exists, continuing with clone...."
  if [ ${freespace[1]} -lt ${space_needed} ]; then
    log_console "Insufficient free space exists in disk group $DG to complete the clone, ensure there is at least ${space_needed}(GB) available in $DG"
    exit 1
  else
    log_console "Disk Group $DG has sufficient free space, continuing with clone......."
  fi
else
  log_console "Disk Group $DG is not found, ensure $DG exists before attempting clone."
  exit 1
fi
}

# Function : Check RESO DG space

check_redo_dg () {

if [ -z "$SECTOR_SIZE" ] ; then
  SECTOR_SIZE=(`sqlplus -s / as sysdba<<eof1
@get_asm_sector_size.sql 
eof1`)
  if [ $? -gt 0 ]; then
    log_console "Required space check failed, make sure ASM is available."
    exit 1
  fi
fi

DG1=`echo $1 | tr -d +`
freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'$DG1'"
eof1`)

if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi
if [ "${freespace[0]}" = "1"  ]; then
  log_console "Disk Group $DG exists, continuing with clone."
  if [ ${freespace[1]} -lt ${space_needed} ]; then
    log_console "Insufficient free space exists in disk group $DG to complete the clone, ensure there is at least ${space_needed}(MB) available in $DG"
    exit 1
  else
    log_console "Disk Group $DG has sufficient free space, continuing with clone......."
  fi
else
  if [ "$DG" = "+REDOC_01" ]; then
    log_console "Missing +REDOC_01 is expected, cotinuing with clone........"
    redoc_missing=true
    export CNT_FILE_3_LOC=+FLASH_01
  else
    redoc_missing=false
    log_console "Disk Group $DG is not found, ensure $DG exists before attempting clone."
    exit 1
  fi
fi
}

# Function : schedule log purge
schedule_purge () {

log_console " "
log_console "Scheduling Purge and Trim, Standby Log Purge and SYS password change Job in OEM"

#-----------------------------------------------------------
# Get standby database count
#-----------------------------------------------------------

export STANDBY_DB_COUNT=$LOGDIR/standby_db_count_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(*) from v\$DATAGUARD_CONFIG where dest_role<>'PRIMARY DATABASE';
exit;" | sqlplus -s sys/${password}@${SOURCE} as sysdba > $STANDBY_DB_COUNT

export STANDBY_DB_COUNT=$(tail -1 $STANDBY_DB_COUNT |sed -e 's/ //g')


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


echo target_list=${ORACLE_SID}_${SERVER_NAME}:oracle_database > /tmp/job_prop_$ORACLE_SID.txt
echo target_list=${ORACLE_SID}_${PRIMARY_HOST}:oracle_database > /tmp/job_prop_prim_$ORACLE_SID.txt

$EMCLI logout | tee -a $LOGFILE
$EMCLI login  -username=oracledba -password=$ORACLEDBAPASS | tee -a $LOGFILE

$EMCLI create_job_from_library -lib_job=PURGE_AND_TRIM_LOGS -name=PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt >> $LOGFILE

if [ $? -gt 0 ] ; then
  log_console "Purge and Trim job scheduling failed for ${DB_UNIQUE_NAME},  Please schedule Job manually"
  log_console " "
else
  log_console "Purge and Trim job has been scheduled for ${DB_UNIQUE_NAME} with default retentions and log size set in OEM library JOB PURGE_AND_TRIM_LOGS"
  log_console "The Job will start from today based on the default schedule set in OEM library JOB PURGE_AND_TRIM_LOGS"
  log_console "Reschedule JOB PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} to update the default values."
  log_console " "
fi

JOB_NO=`echo $STANDBY_DB_COUNT`
log_console "Attempting to add job ${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE"  
$EMCLI create_job_from_library -lib_job=STDBY_ARCHIVE_LOG_PURGE -name=${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt >> $LOGFILE

RET_CD=$?
if [ $RET_CD -eq 254 ]; then
  JOB_NO=1
  log_console "Attempting to add job ${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE"
  $EMCLI create_job_from_library -lib_job=STDBY_ARCHIVE_LOG_PURGE -name=${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt >> $LOGFILE
  RET_CD=$?
  while [ $RET_CD -eq 254 ] && [ $JOB_NO -lt 5 ]; do
    let JOB_NO=JOB_NO+1
    log_console "Attempting to add job ${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE"
    $EMCLI create_job_from_library -lib_job=STDBY_ARCHIVE_LOG_PURGE -name=${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt >> $LOGFILE
    RET_CD=$?
  done
fi

if [ $RET_CD -gt 0 ] ; then
  log_console "STDBY ARCHIVE LOG PURGE job scheduling failed for ${DB_UNIQUE_NAME},  Please schedule Job manually"
  log_console " "
else
  log_console "STDBY ARCHIVE LOG PURGE job has been scheduled for ${DB_UNIQUE_NAME} "
  log_console "The Job will start from today based on the default schedule set in OEM library JOB STDBY_ARCHIVE_LOG_PURGE"
  log_console "Reschedule ${ORACLE_SID}_STDBY${JOB_NO}_ARCHIVE_LOG_PURGE to update the default values."
  log_console " "
fi

$EMCLI create_job_from_library -lib_job=CHANGE_DATAGUARD_SYS_PWD -name=${ORACLE_SID}_CHANGE_DATAGUARD_SYS_PWD -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_prim_${ORACLE_SID}.txt >> $LOGFILE
RET_CD=$?

if [ $RET_CD -eq 254 ]; then
  log_console "Job ${ORACLE_SID}_CHANGE_DATAGUARD_SYS_PWD already exists, no action to take"
else
  if [ $RET_CD -gt 0 ] ; then
    log_console "CHANGE DATAGUARD SYS PWD job scheduling failed for ${DB_UNIQUE_NAME},  Please schedule Job manually"
    log_console " "
  else
    log_console "CHANGE DATAGUARD SYS PWD  job has been scheduled for ${DB_UNIQUE_NAME}"
    log_console "The Job will start from today based on the default schedule set in OEM library JOB CHANGE_DATAGUARD_SYS_PWD"
    log_console "Reschedule ${ORACLE_SID}_CHANGE_DATAGUARD_SYS_PWD to update the default values."
    log_console " "
  fi
fi

$EMCLI logout | tee -a $LOGFILE
rm /tmp/job_prop_$ORACLE_SID.txt
rm /tmp/job_prop_prim_$ORACLE_SID.txt
log_console " "
}

# Function : SUSPEND/RESUME OEM jobs
change_job_status () {

log_console " "

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


$EMCLI logout >> $LOGFILE
$EMCLI login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE

case $1 in
   suspend)
      log_console "The following Jobs are scheduled or running for the primay database in OEM"
      log_console " "
      $EMCLI get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${ORACLE_SID}_${PRIMARY_HOST}:oracle_database | tee -a $LOGFILE
      log_console " "
      $EMCLI $1_job  -owner=ORACLEDBA -targets=${ORACLE_SID}_${PRIMARY_HOST}:oracle_database | tee -a $LOGFILE
      ;;
   resume)
      $EMCLI $1_job  -owner=ORACLEDBA -targets=${ORACLE_SID}_${PRIMARY_HOST}:oracle_database | tee -a $LOGFILE
      log_console "The following Jobs are scheduled or running for the primary database in OEM"
      log_console " "
      $EMCLI get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${ORACLE_SID}_${PRIMARY_HOST}:oracle_database | tee -a $LOGFILE
      log_console " "
      ;;
esac

if [ $? -gt 0 ] ; then
  log_console "Job Status Change Failed....."
  $EMCLI logout >> $LOGFILE
  log_console " "
  return 1
else
  $EMCLI logout >> $LOGFILE
  log_console " "
  return 0
fi
}


add_listener_entry () {

cat << label1 >> $TNS_ADMIN/listener.ora

$ORACLE_SID =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = ${ORACLE_SID}_IPC))
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOSTNAME})(PORT = ${PORT}))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC${PORT}))
    )
  )

SECURE_REGISTER_${ORACLE_SID} = (IPC)

ADR_BASE_${ORACLE_SID} = ${STD_DBMS_DIR}/app/oracle

SID_LIST_${ORACLE_SID} =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLE_SID}_${SERVER_NAME}_dgmgrl)
      (ORACLE_HOME = ${STD_DBMS_DIR}/app/oracle/product/${VERSION}/db_1)
      (SID_NAME = ${ORACLE_SID})
    )
  )


ENABLE_GLOBAL_DYNAMIC_ENDPOINT_${ORACLE_SID}=ON                # line added by Agent
VALID_NODE_CHECKING_REGISTRATION_${ORACLE_SID}=SUBNET          # line added by Agent

label1
}

add_tns_entry () {
cat << label2 >> $TNS_ADMIN/tnsnames.ora

${1}_${2} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${2})(PORT = ${3}))
    )
    (CONNECT_DATA =
      (SID = ${1})
    )
  )

label2
}

#--------------------------------------------------------------------------------l
#End of Functions
#--------------------------------------------------------------------------------

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/create_standby_db_$1_$DATEVAR.out
EMCLI=${STD_DBMS_DIR}/app/oracle/product/emcli/emcli
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [[ $1 == CDB[0-9][0-9]C ]] || [[ $1 == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]]  ; then
  if [ "$#" -lt "2" ]; then
    log_console "Usage: $0  target_db_name source_host "
    log_console Parms: $*
    exit 1
  else
    PRIMARY_HOST=`echo $2 | tr '[:upper:]' '[:lower:]'`
    PORT=1521
    log_console "Start $1 Clone  `uname -svrn` at `date` using $0 $*"
  fi
else
  if [ $# -ne 3 ]; then
    log_console "Usage: $0  target_db_sid target_db_port primary_host"
    log_console Parms: $*
    exit 1
  fi

  "$2" -eq "$2" 2>/dev/null

  if [ "$2" -eq "$2" ] 2>/dev/null; then
    PRIMARY_HOST=`echo $3 | tr '[:upper:]' '[:lower:]'`
    PORT=$2
    log_console "Start $1 Clone  `uname -svrn` at `date` using $0 $*"
  else
    log_console "Invalid Port number specified, value most bt numeric"
    log_console "Usage: $0  target_db_sid target_db_port primary_host"
    log_console Parms: $*
    exit 1
  fi
fi

log_console "Start create standby database for $1  `uname -svrn` at `date` using $0 $*"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] 
if test $? -eq 0; then
  ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z] >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  active...drop it before attempting clone"
  exit 1
fi
log_console " "

export ORACLE_SID=+ASM
export ORAENV_ASK=NO
 
. oraenv >> $LOGFILE

SOURCE_DB=$1
export SOURCE=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${PRIMARY_HOST})(PORT=${PORT}))(CONNECT_DATA=(SID=$1)))"'"'`
#export TNS_ADMIN=/orahome/u01/app/oracle/product/$VERSION/db_1/network/admin
export P_CONNECT=$1_${PRIMARY_HOST}

log_console "Enter the number of disk channels desired for rman clone:"

select channel_cnt in "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16"; do
case $channel_cnt in
  [1-9]|10)
    break;;
  1[1-6])
    break;;
   *)
    echo 'Invalid channel count, try again'
esac
done


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

sqlplus -S sys/$password@$SOURCE as sysdba<<eof1 >> $LOGFILE
whenever sqlerror exit 1
exit;
eof1

if [ $? -gt 0 ]; then
  log_console "Invalid Password or connection error encountered, try again"
  exit 1
else
  log_console "Log on successful, continuing with clone....."
fi

#----------------------------------------------------------------------------
# Check if data and index diskgroup exist and have adequate space
#----------------------------------------------------------------------------

case $STD_DATA_DG in
"+DATA1")
  export DATA_DG=$LOGDIR/DATA_DG_$ORACLE_SID.log
  echo "set echo off ver off pages 0 trims on head off feed off
  select listagg (name,' ') within group (order by name) dg from ( select unique replace(regexp_substr(name,'[^/]+', 1, level),'_0') name from v\$datafile connect by regexp_substr(name, '[^,]+', 1, level) is not null);
  exit;" |  sqlplus -s "sys/$password@$SOURCE" as sysdba > $DATA_DG

  export DATA_DG=$(tail -1 $DATA_DG |sed 's/\s*$//g')
;;
*)
  export DATA_DG=$LOGDIR/DATA_DG_$ORACLE_SID.log
  echo "set echo off ver off pages 0 trims on head off feed off
  select listagg (name,' ') within group (order by name) dg from ( select unique regexp_substr(name,'[^/]+', 1, level) name from v\$datafile connect by regexp_substr(name, '[^,]+', 1, level) is not null);
  exit;" |  sqlplus -s "sys/$password@$SOURCE" as sysdba > $DATA_DG

  export DATA_DG=$(tail -1 $DATA_DG |sed 's/\s*$//g')
;;
esac


for DG in  $DATA_DG
  do
    check_data_dg $DG
  done

#--------------------------------------------------------------------
# Check to ensure FLASH disk group exists
#-------------------------------------------------------------------
DG=`echo $STD_ARCHIVE_LOG_DG | tr -d +`
freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'$DG'"
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi

if [ ${freespace[0]} -eq 1 ]; then
  log_console "Disk Group $STD_ARCHIVE_LOG_DG exists, continuing with clone......."
else
  log_console "Disk Group $STD_ARCHIVE_LOG_DG is not found, ensure $STD_ARCHIVE_LOG_DG exists before attempting clone."
  exit 1
fi


#----------------------------------------------------------------------------
# Check if REDO Disk Groups exist and have adequate space
#----------------------------------------------------------------------------
LOG_SIZE=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_log_size.sql
eof1`)
if [ $? -gt 0 ]; then
  log_console "Log size fetch failed, make sure source database at $SOURCE is available."
  exit 1
fi

LOG_COUNT=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_log_number.sql
eof1`)
if [ $? -gt 0 ]; then
  log_console "Log number fetch failed, make sure source database at $SOURCE is available."
  exit 1
fi

space_needed=$(($LOG_COUNT * $LOG_SIZE))

case $STD_REDO1_DG in
"+REDO1")
  export REDO_DG=${LOGDIR}/REDO_DG_$ORACLE_SID.log
   echo "set echo off ver off pages 0 trims on head off feed off
   select listagg (member,' ') within group (order by member) dg from ( select unique replace(replace(replace(regexp_substr(member,'[^/]+', 1, level),'_01'),'A','1'),'B','2') member from v\$logfile connect by regexp_substr(member, '[^,]+', 1, level) is not null);
   exit;" |  sqlplus -s "sys/$password@$SOURCE" as sysdba > $REDO_DG

  export REDO_DG=$(tail -1 $REDO_DG |sed 's/\s*$//g')
;;
*)
  export REDO_DG=${LOGDIR}/REDO_DG_$ORACLE_SID.log
   echo "set echo off ver off pages 0 trims on head off feed off
   select listagg (member,' ') within group (order by member) dg from ( select unique regexp_substr(member,'[^/]+', 1, level) member from v\$logfile connect by regexp_substr(member, '[^,]+', 1, level) is not null);
   exit;" |  sqlplus -s "sys/$password@$SOURCE" as sysdba > $REDO_DG

  export REDO_DG=$(tail -1 $REDO_DG |sed 's/\s*$//g')
;;
esac

for DG in  $REDO_DG
  do
    check_redo_dg $DG
    if [ '${DG}' = '+REDOC_01' ]; then
      export CNT_FILE_3_LOC=+REDOC_01
    fi
  done

if [ '${CNT_FILE_3_LOC}' != '+REDOC_01' ]; then
  export CNT_FILE_3_LOC=+FLASH_01
fi

#----------------------------------------------------------------------------------
# Fetch Version from Primary database
#----------------------------------------------------------------------------------

export MAJOR_REL=$LOGDIR/major_rel_$1.log
echo "set echo off ver off pages 0 trims on head off feed off
select substr(version,1,2) from v\$instance;
exit;" | sqlplus -s "sys/$password@$SOURCE" as sysdba > $MAJOR_REL

export MAJOR_REL=$(tail -1 $MAJOR_REL |sed -e 's/ //g' | cut -d ' ' -f1)

export VERSION=$LOGDIR/version_$1.log

echo "set echo off ver off pages 0 trims on head off feed off
select REGEXP_SUBSTR (SYS_CONTEXT ('USERENV','ORACLE_HOME'), '[0-9]+[.][0-9]+[.][0-9]+') from dual
exit;" | sqlplus -s "sys/$password@$SOURCE" as sysdba > $VERSION

export VERSION=$(tail -1 $VERSION |sed -e 's/ //g' | cut -d ' ' -f1)
 
export TNS_ADMIN=${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1/network/admin

log_console "Primary database $1 is at PSU level $VERSION"
if [ -d ${STD_DBMS_DIR}/app/oracle/product/${VERSION} ]; then
  log_console "Oracle DBMS software version $VERSION is installed, continuing with clone......"
else
  log_console "Oracle DBMS software version $VERSION is not intalled."
  exit 1
fi

export ORACLE_HOME=${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1

#----------------------------------------------------------------
# Check if source is in archivelog mode
#---------------------------------------------------------------
export LOG_MODE=$LOGDIR/log_mode_$1.log
echo "set echo off ver off pages 0 trims on head off feed off
select log_mode from v\$database
exit;" | sqlplus -s "sys/$password@$SOURCE" as sysdba > $LOG_MODE

export LOG_MODE=$(tail -1 $LOG_MODE |sed -e 's/ //g' | cut -d ' ' -f1)

if [ $LOG_MODE = "ARCHIVELOG" ] ; then
  log_console "Source database is in archivelog mode continuing with clone......."
else
  log_console  "Source database must be in archivelog mode, please place source database in archivelog mode and try again"
  exit 1
fi

#------------------------------------------------------------
# Check if selected port is free
#-----------------------------------------------------------
if [[ $1 != CDB[0-9][0-9]C ]] && [[ $1 != C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
  netstat -tlen | grep :$PORT >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    log_console "Selected port is in use, please free the port or select another"
    exit 1
  fi
fi

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

export ORACLE_SID=$1
ORATAB=/etc/oratab
grep $ORACLE_SID $ORATAB | grep -v $ORACLE_SID[0-z] | grep -v ${ORACLE_SID}_del >/dev/null 2>&1
if [ $? -eq 0 ]; then
  log_console "Database already exists in ORATAB, drop/remove it before attempting clone"
  exit 1
else
  log_console "Adding ORATAB entry"
  echo $ORACLE_SID:${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1:N >> $ORATAB
fi


shopt -s expand_aliases
export ORAENV_ASK=NO

. oraenv >> $LOGFILE
export PATH=$ORACLE_HOME/bin:$PATH
RCATPASS=`rcatpass`

if [ -z ${CONTEXT_NAME+x} ]; then
  export TNS_ADMIN=$ORACLE_HOME/network/admin
else
  export TNS_ADMIN=$ORACLE_HOME/network/admin/$CONTEXT_NAME
  mkdir -p $TNS_ADMIN
fi


#------------------------------------------------------------
# Configure Listener 
#------------------------------------------------------------

export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`

if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
  GI_RELEASE=`grep +ASM /etc/oratab | cut -d / -f7`
  cp -p /orastage/u177/CDB_ASM_listener.ora $TNS_ADMIN/listener.ora
  perl -i -pe "s/<host_name>/$HOSTNAME/g" $TNS_ADMIN/listener.ora
  perl -i -pe "s/<dbms_release>/$VERSION/g" $TNS_ADMIN/listener.ora
  perl -i -pe "s/<cdb_sid>/$ORACLE_SID/g" $TNS_ADMIN/listener.ora
  perl -i -pe "s/<gi_release>/$GI_RELEASE/g" $TNS_ADMIN/listener.ora
  lsnrctl stop listener
  lsnrctl start listener
else
  if [ -f $TNS_ADMIN/listener.ora ] ; then
    grep -i "${ORACLE_SID} =" $TNS_ADMIN/listener.ora >/dev/null
    if [ $? -gt 0 ] ; then
      log_console "Adding target database listener config"
      cp $TNS_ADMIN/listener.ora $TNS_ADMIN/listener.ora_bkup_$DATEVAR
      add_listener_entry 
    else
      log_console "Target database listener entry exists"
    fi
  else
    add_listener_entry
  fi
fi

#------------------------------------------------------------
# Configure TNS entries
#------------------------------------------------------------

if [ -f $TNS_ADMIN/tnsnames.ora ] ; then
  cp $TNS_ADMIN/tnsnames.ora $TNS_ADMIN/tnsnames.ora_bkup_$DATEVAR
  grep -i ${ORACLE_SID}_${SERVER_NAME} $TNS_ADMIN/tnsnames.ora >/dev/null
  if [ $? -gt 0 ] ; then
    log_console "Adding target database TNS entry"
    add_tns_entry ${ORACLE_SID} ${SERVER_NAME} ${PORT}
  else
    log_console "Target database TNS entry exists"
  fi
  grep -i ${ORACLE_SID}_${PRIMARY_HOST} $TNS_ADMIN/tnsnames.ora >/dev/null
    if [ $? -gt 0 ] ; then
    log_console "Adding source database TNS entry"
    add_tns_entry ${ORACLE_SID} ${PRIMARY_HOST} ${PORT}
  else
    log_console "Source database TNS entry exists"
  fi
else
  add_tns_entry ${ORACLE_SID} ${SERVER_NAME} ${PORT}
  add_tns_entry ${ORACLE_SID} ${PRIMARY_HOST} ${PORT}
fi

#---------------------------------------------------------------------------
#  Check for sufficient free huge pages to accomodate source SGA
#---------------------------------------------------------------------------
export SGA_MAX_SIZE=$LOGDIR/sga_max_size_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select  value from v\$parameter where name = 'sga_max_size';
exit;" | sqlplus -s "sys/$password@\"$P_CONNECT\"" as sysdba > $SGA_MAX_SIZE

export SGA_MAX_SIZE=$(tail -1 $SGA_MAX_SIZE |sed -e 's/ //g')
log_console "Source SGA MAX SIZE: $SGA_MAX_SIZE"

FREE_HUGE_PAGES=(`grep HugePages_Free /proc/meminfo | awk ' {print $2} '`)

if [ $(($FREE_HUGE_PAGES*2097152)) -lt $SGA_MAX_SIZE ]; then
   log_console "Free Huge Pages: $FREE_HUGE_PAGES"
   log_console "Free Huge Pages required to accmodate a $SGA_MAX_SIZE byte sga: $(($SGA_MAX_SIZE/2097152))"
   log_console "Insufficient Huge Pages allocated to accomodate the new standby database"
   exit 1
else
   log_console "Free huge pages is sufficient continuing with clone......."
fi

#--------------------------------------------------------
# Prepare Primary Database
#--------------------------------------------------------

rm $SQLPATH/connect_to_primary.sql
cat << label3 > $SQLPATH/connect_to_primary.sql
connect sys/$password@${ORACLE_SID}_${PRIMARY_HOST} as sysdba;
set echo on
alter system set dg_broker_start=TRUE;
label3

export REDO_SIZE=$LOGDIR/redo_size_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select max(bytes/1024/1024) from gv\$log;
exit;" | sqlplus -s "sys/$password@\"$P_CONNECT\"" as sysdba > $REDO_SIZE

export REDO_SIZE=$(tail -1 $REDO_SIZE |sed -e 's/ //g')
log_console "Redo Size: $REDO_SIZE"

export REDO_COUNT=$LOGDIR/redo_count_$PRIMARY_DB.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(distinct group#) from v\$log where thread#=1;
exit;" | sqlplus -s "sys/$password@\"$P_CONNECT\"" as sysdba > $REDO_COUNT

export REDO_COUNT=$(tail -1 $REDO_COUNT |sed -e 's/ //g')
log_console "Redo Count: $REDO_COUNT"

export STANDBY_COUNT=$LOGDIR/STANDBY_count_$PRIMARY_DB.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(distinct group#) from v\$standby_log ;
exit;" | sqlplus -s "sys/$password@\"$P_CONNECT\"" as sysdba > $STANDBY_COUNT

export STANDBY_COUNT=$(tail -1 $STANDBY_COUNT |sed -e 's/ //g')
log_console "Standby Redo Count: $STANDBY_COUNT"

export FORCE_LOGGING=$LOGDIR/force_logging_$PRIMARY_DB.log
echo "set echo off ver off pages 0 trims on head off feed off
select force_logging from v\$database;
exit;" | sqlplus -s "sys/$password@\"$P_CONNECT\"" as sysdba > $FORCE_LOGGING

export FORCE_LOGGING=$(tail -1 $FORCE_LOGGING |sed -e 's/ //g')
log_console "Force Logging: $FORCE_LOGGING"

if [ $STANDBY_COUNT -eq 0 ]; then
  log_console "No Standby Redologs exist on the primary database. Adding Standby logs......."
  DG=( $STD_REDO1_DG $STD_REDO2_DG )
  DG_COUNT_1=0
  DG_COUNT_2=1
  GROUP_NUMBER=11
  (( REDO_NUMBER=$REDO_COUNT + 12))
  while [[ $GROUP_NUMBER -lt $REDO_NUMBER ]]
  do
    echo "alter database add standby logfile thread 1 group ${GROUP_NUMBER} ('${DG[${DG_COUNT_1}]}', '${DG[${DG_COUNT_2}]}') size ${REDO_SIZE}m blocksize 4096;" >> $SQLPATH/connect_to_primary.sql
    (( GROUP_NUMBER = $GROUP_NUMBER + 1 ))
  done

fi

if [ $FORCE_LOGGING = 'NO' ]; then
 echo "alter database force logging;" >> $SQLPATH/connect_to_primary.sql
fi


sqlplus -S /nolog <<EOF  >>$LOGFILE
whenever sqlerror exit 1
@connect_to_primary.sql
exit;
EOF

if [ $? -eq 0 ]; then
  log_console "Primary database ${ORACLE_SID}_${PRIMARY_HOST} prepare complete, continuing with clone"
else
  log_console "Primary database ${ORACLE_SID}_${PRIMARY_HOST} prepare failed"
  exit 1
fi


#------------------------------------------------------------
#  Build/Start Database Instance
#------------------------------------------------------------

mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/rman
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql

echo DB_NAME=$ORACLE_SID > $ORACLE_HOME/dbs/init_for_clone.pfile
orapwd file=$ORACLE_HOME/dbs/orapw${ORACLE_SID} password=$password entries=10 


sqlplus -S  <<EOF  >>$LOGFILE
connect / as sysdba
whenever sqlerror exit failure 1
startup nomount pfile=?/dbs/init_for_clone.pfile
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Instance Startup Failed"
  exit 1
else
  log_console  "Instance Startup Successful"
fi


if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
  echo
else
  srvctl add listener -l $ORACLE_SID -oraclehome $ORACLE_HOME -endpoints "TCP:${PORT}/IPC:${ORACLE_SID}_IPC" >>$LOGFILE 
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> srvctl add listener failed!!!"
    exit 1
  fi

  srvctl setenv listener -l $ORACLE_SID -env "TNS_ADMIN=$TNS_ADMIN"
  srvctl start listener -l $ORACLE_SID 
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> srvctl start listener failed!!!"
    exit 1
  fi
fi

mkdir -p ${STD_ADMP_DIR}/${ORACLE_SID}/adump

#----------------------------------------------------------
# Suspend Primary database OEM Jobs
#----------------------------------------------------------

change_job_status suspend

echo -e "run" '\n'"{" >  $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
for ((i=1;i<=channel_cnt;i++));
  do
    echo "ALLOCATE CHANNEL d${i} TYPE DISK ;" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
    echo "ALLOCATE AUXILIARY CHANNEL a${i} TYPE DISK ;" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
  done

cat << label4 >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd

duplicate target database for standby 
from active database  
section size 32g
spfile
set db_unique_name='${ORACLE_SID}_${SERVER_NAME}'
set control_files='${STD_REDO1_DG}','${STD_REDO2_DG}','${STD_DATA_DG}'
set log_archive_dest_1='location=${STD_ARCHIVE_LOG_DG}'
set db_create_online_log_dest_1='${STD_REDO1_DG}'
set db_create_online_log_dest_2='${STD_REDO2_DG}'
set db_create_file_dest='${STD_DATA_DG}'
set db_recovery_file_dest='${STD_FRA_DG}'
set log_file_name_convert '+REDOA_01','${STD_REDO1_DG}','+REDOB_01','${STD_REDO2_DG}'
set local_listener='(DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=${ORACLE_SID}_IPC)))'
set audit_file_dest='${STD_ADMP_DIR}/${ORACLE_SID}/adump'
set log_archive_dest_2=' '
set log_archive_dest_3=' '
set log_archive_dest_4=' '
set log_archive_dest_5=' '
set log_archive_dest_6=' '
label4

DG=$DATA_DG
declare -a DATA_DG=(${DG[@]/+IND*})
declare -a IND_DG=(${DG[@]/+DATA* })

if [[ "$STD_DATA_DG" == *"_"* ]]; then
  STD_DATA_STR=+DATA_0
  STD_IND_STR=+IND_0
else
  STD_DATA_STR=+DATA
  STD_IND_STR=+IND
fi

if [ ${#DATA_DG[@]} -ne 0 ]; then
  echo -ne "set db_file_name_convert " > $LOGDIR/file_convert_string.dat
  for (( i=1; i<${#DATA_DG[@]}+1; i++ ));
    do
      if [ $i == ${#DATA_DG[@]} ]; then
        echo -ne "'+DATA_0${i}','$STD_DATA_STR${i}'" >> $LOGDIR/file_convert_string.dat
      else
        echo -ne "'+DATA_0${i}','$STD_DATA_STR${i}'," >> $LOGDIR/file_convert_string.dat
      fi
    done
fi

if [ ${#IND_DG[@]} -ne 0 ]; then
  for (( i=1; i<${#IND_DG[@]}+1; i++ ));
    do
      echo -ne ",'+IND_0${i}','$STD_IND_STR${i}'" >> $LOGDIR/file_convert_string.dat
    done
fi
cat $LOGDIR/file_convert_string.dat >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd

if [ "$MAJOR_REL" > "12" ] ; then
  echo -e "\nset \"_disk_sector_size_override\"='true'" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
fi

echo -e "\nnofilenamecheck\n;\n}" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd



rman_loc=$ORACLE_BASE/admin/$ORACLE_SID/rman
rman_job=duplicate_${SOURCE_DB}
NOW=`/bin/date '+%m-%d-%Y-%H%M%S'`
rman_cmdfile=${rman_loc}/${rman_job}.cmd
rman_logfile=${rman_loc}/${rman_job}_${NOW}.log
rman_outfile=$LOGFILE
rman_msgfile=$LOGFILE
debug_logfile=${rman_loc}/${rman_job}_${NOW}.log
export DEST=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${SERVER_NAME})(PORT=${PORT}))(CONNECT_DATA=(SID=${ORACLE_SID})))"'"'`

log_console "Starting RMAN clone, please wait....."
log_console "Review $rman_logfile in another session to see clone progress"

log_console " "


########################################################################################
echo "Begin RMAN Job : " `/bin/date`                           >> $rman_outfile
echo -e "\n===========================================\n"      >> $rman_outfile
echodo rman target sys/$password@$P_CONNECT \
auxiliary sys/$password@$DEST \
cmdfile=${rman_cmdfile} log=${rman_logfile}                    >> $rman_outfile 2>> $rman_outfile
echo -e "\n===========================================\n"      >> $rman_outfile
echo "End   RMAN Job : " `/bin/date`                           >> $rman_outfile
echo -e "\n\n\n\n"                                             >> $rman_outfile
########################################################################################

cat ${rman_logfile} | grep 'Finished Duplicate Db' >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo Including rman duplicate log..... >> $LOGFILE
  cat ${rman_logfile} >> $LOGFILE
  echo ========== End of rman duplicate log =========== >> $LOGFILE
  log_console "RMAN Duplicate Successful, continuing with clone"
else
  echo Including rman duplicate log..... >> $LOGFILE
  cat ${rman_logfile} >> $LOGFILE
  echo ========== End of rman duplicate log ============ >> $LOGFILE
  log_console "RMAN Duplicate Failed!!!"
  log_console "Attempting to drop database $ORACLE_SID......"
  $ORACLE_HOME/bin/dbca -sysPassword $password -silent -deleteDatabase -sourceDB $ORACLE_SID | tee -a $LOGFILE
  log_console "Drop of database $ORACLE_SID complete"
  log_console "Removing listener $ORACLE_SID"
  srvctl stop listener -l $ORACLE_SID | tee -a $LOGFILE
  srvctl remove listener -l $ORACLE_SID | tee -a $LOGFILE
  log_console "Listener $ORACLE_SID has been removed"
  log_console "Restoring network configuration files"
  if [ -f $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR ] ; then
    cp $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR $ORACLE_HOME/network/admin/tnsnames.ora
  else
    rm $ORACLE_HOME/network/admin/tnsnames.ora
  fi
  if [ -f $ORACLE_HOME/network/admin/listener.ora_bkup_$DATEVAR ] ; then
    cp $ORACLE_HOME/network/admin/listener.ora_bkup_$DATEVAR $ORACLE_HOME/network/admin/listener.ora
  else
    rm $ORACLE_HOME/network/admin/listener.ora
  fi
  log_console "Network configuration files have been restored"
  log_console "Before re-attempting the clone to $ORACLE_SID, perform the following actions:"
  log_console "    1. Ensure database $ORACLE_SID has been dropped"
  log_console "    2. Ensure listener  $ORACLE_SID has been dropped"
  log_console "    3. Ensure network configuration files have been restored"    
  log_console " "
  exit 1
fi

cat << label5 > $SQLPATH/set_stby_mgmt.sql
connect sys/$password@${ORACLE_SID}_${PRIMARY_HOST} as sysdba;
set echo on
alter system set standby_file_management = 'AUTO';
connect / as sysdba;
alter system set standby_file_management = 'AUTO';
label5

log_console "Set standby file managment to automatic"
sqlplus -S /nolog <<EOF  >>$LOGFILE
whenever sqlerror exit 1
@set_stby_mgmt.sql
exit;
EOF

if [ $? -eq 0 ] ; then
  log_console "Set standby file managment to automatic complete"
else
  log_console "Set standby file managment to automatic failed"
  exit 1
fi

#------------------------------------------------------------------
#  Configure HAS
#------------------------------------------------------------------

log_console "Adding Standby database to HAS"

srvctl add database -db ${ORACLE_SID}_${SERVER_NAME} -oraclehome ${ORACLE_HOME} -spfile ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora -instance ${ORACLE_SID} -diskgroup "${STD_DATA_DG:1},${STD_REDO1_DG:1},${STD_REDO2_DG:1}" -role "PHYSICAL_STANDBY" -startoption "MOUNT" | tee -a $LOGFILE
 
srvctl stop database -db ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
srvctl start database -db ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE

#-----------------------------------------------------------------
#  Configure Data Guard Broker
#-----------------------------------------------------------------

dgmgrl -echo sys/$password@${SOURCE} "show configuration" >> $LOGFILE
if [ $? -eq 0 ]; then
  log_console "Dataguard broker confiration exists, adding standby database to existing configuration"
else
  log_console "Creating datagaurd broker configuration"
  dgmgrl -echo sys/$password@${SOURCE} "create configuration '${ORACLE_SID}' as primary database is '${ORACLE_SID}_${PRIMARY_HOST}' connect identifier is ${SOURCE}" | tee -a $LOGFILE
  dgmgrl -echo sys/$password@${SOURCE} "edit database '${ORACLE_SID}_${PRIMARY_HOST}' set property StaticConnectIdentifier=${SOURCE}" | tee -a $LOGFILE
fi 

dgmgrl -echo sys/$password@${SOURCE} "show database '${ORACLE_SID}_${SERVER_NAME}'" | tee -a $LOGFILE
if [ $? -eq 0 ]; then
   dgmgrl -echo sys/$password@${SOURCE} "remove database '${ORACLE_SID}_${SERVER_NAME}'" | tee -a $LOGFILE
fi

dgmgrl -echo sys/$password@${SOURCE} "add database '${ORACLE_SID}_${SERVER_NAME}' as  connect identifier is ${DEST} maintained as physical" | tee -a $LOGFILE
dgmgrl -echo sys/$password@${SOURCE} "edit database '${ORACLE_SID}_${SERVER_NAME}' set property StaticConnectIdentifier=${DEST}" | tee -a $LOGFILE
dgmgrl -echo sys/$password@${SOURCE} "enable configuration" | tee -a $LOGFILE
dgmgrl -echo sys/$password@${SOURCE} "EDIT CONFIGURATION SET PROPERTY OperationTimeout=120;" | tee -a $LOGFILE
dgmgrl -echo sys/$password@${SOURCE} "edit database '${ORACLE_SID}_${PRIMARY_HOST}' set state='TRANSPORT-ON'" | tee -a $LOGFILE

log_console "Bouncing Standby database with svrctl"

srvctl stop database -d ${ORACLE_SID}_${SERVER_NAME}
srvctl start database -d ${ORACLE_SID}_${SERVER_NAME}

#------------------------------------------------------------
# Create symbolic link from $ORACLE_BASE/admin/$ORACLE_SID
# to $ORACLE_HOME to suuport Gardium and the viloin agent
#------------------------------------------------------------

if [ -e $ORACLE_BASE/admin/$ORACLE_SID/oracle_home ] ; then
   log_console "The oracle home link already exists, recreating the link"
   rm  $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link"
   else
     log_console "Oracle Home symbolic link has been re-created"
   fi
else
   ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link"
   else
     log_console "Oracle Home symbolic link has been created"
   fi
fi

#-------------------------------------------------------------
# Configure RMAN archivelog deletion policies for Data Guard
#--------------------------------------------------------------

rman target / catalog $ORACLE_SID/`echo $RCATPASS`@$RCATDB<<EOF >>$LOGFILE
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;
exit;
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Standby deletion policy configuration failed"
  log_console "Please confiure standby database archive log deletion policy manually"
else
   log_console "Standby database archive log deletion policy has been configured"
fi

rman target sys/$password@$SOURCE catalog $ORACLE_SID/`echo $RCATPASS`@$RCATDB<<EOF >>$LOGFILE
CONFIGURE ARCHIVELOG DELETION POLICY TO SHIPPED TO ALL STANDBY BACKED UP 1 TIMES to SBT_TAPE;
exit;
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Primary database deletion policy configuration failed"
  log_console "Please confiure primary database archive log deletion policy manually"
else
   log_console "Primary database archive log deletion policy has been configured"
fi

#----------------------------------------------------------
# Resume Primary database OEM Jobs 
#----------------------------------------------------------
change_job_status resume

#----------------------------------------------------------
#  Add Standby database to OEM
#----------------------------------------------------------
log_console " "
log_console "Starting OEM update........."

if [ -x $ORACLE_BASE/product/emcli/emcli ] ; then
  log_console " emcli exists and is executable, updating OEM"
  log_console " "
  $EMCLI add_target -name="${ORACLE_SID}_${SERVER_NAME}" -type="oracle_database" -host="$HOSTNAME" -credentials="UserName:sys;password:$password;Role:sysdba" -properties="SID:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};MachineName:$HOSTNAME" -groups="Unassigned:composite"
  case $? in
    [1-5]|[7-23]|[219-223]*) log_console "OEM Database Target add has failed!!!  Please add standby database to OEM manually" ;;
    6) log_console "OEM database target already exists in OEM, this is expected on a standby database rebuild" ;;
    *) $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Comment:Standard Build"
       $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Contact:(Oracle DBA)"
       schedule_purge;;
  esac
  if [[ $1 == CDB[0-9][0-9]C ]] || [[ $1  == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
    echo
  else
    $EMCLI add_target -name="${ORACLE_SID}_${HOSTNAME}" -type="oracle_listener" -host="$HOSTNAME"  -properties="LsnrName:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};ListenerOraDir:${TNS_ADMIN};Machine:$HOSTNAME" -groups="Unassigned:composite"
    case $? in
      [1-5]|[7-23]|[219-223]*) log_console "OEM Listener Target add has failed!!!  Please add listener to OEM manually" ;;
      6) log_console "OEM  listener target already exists in OEM, this is expected on a standby database rebuild" ;;
      *) $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${HOSTNAME}:oracle_listener:Contact:(Oracle DBA)" ;;
    esac
  fi
else
  log_console "emcli is not installed on this server, please add standby database to OEM manually"
fi

  


log_console " "
log_console "IMPORTANT!!!!!"
log_console "Before attempting a switchover, you must ensure the following is added to the listener definition on ${PRIMARY_HOST}"
log_console "(GLOBAL_DBNAME = ${ORACLE_SID}_${PRIMARY_HOST}_dgmgrl)"
log_console " "
log_console "Create Standby Database   $1 complete  `uname -svrn` at `date` using $0 "
echo 


exit 0

