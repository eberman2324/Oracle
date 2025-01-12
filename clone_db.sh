#!/bin/bash
###########################################################################################################################
#  clone_db.sh is executed to clone any standard build database   
#
#  usage: $ . clone_db.sh   <target_db_name>  <target_db_port> <source_db_name> <source_port> <source_host>
#
#   Use the following technique to execute the script in background 
#
#         nohup clone_db.sh TSTNGCLN 1631 TSTNGMGR 1630 xhepydbw2d  <<< $'<number of channels>\n<SYS password>\n' &
#
#  For example:
#         nohup clone_db.sh TSTNGCLN 1631 TSTNGMGR 1630 xhepydbw2d  <<< $'4\nlocked99999\n' &
#
#         where 4 is the number of channels and locked99999 is the sys password.
#
#
#  Maintenance Log:
#  1.0  01/2018      R. Ryan     New Script 
#  1.1  01/2018      R. Ryan     Accounted for no index diskgroup on the target when one exists on the source
#                                switched to correct OMS depeneding on the source database environment
#                                to suspend/resume source database jobs.
#  2.0  01/2018      R. Ryan     Provided the ability to specify a redo log size and number to overide the source database.
#  2.1  01/2018      R. Ryan     Corrected issue with emcli login timeout when resuming source database jobs.
#                                Do not raise an error when OEM target already exists when adding OEM targets
#  2.2  03/2018      R. Ryan     Corrected issue with targets added as oracledba not puppet, schedule log purge job
#  2.3  03/2018      R. Ryan     Made change to ignore dummy ORATAB entry using in RMAN/TSM cleanup
#                                Prevneted duplicate listner.ora and tnsnames.ora entries from being created
#                                Added check for source database in archivelog mode
#  2.4  03/2018      R. Ryan     Added Standard Build comment when adding OEM database target.
#  2.5  07/2018      R. Ryan     Corrected issue with check to see if the source db TNS entry exists.
#  3.0  01/2019      R. Ryan     18c support
#  3.1  02/2019      R. Ryan     reset the spfile file prameters instance_name, log_archive_config, fal_server and dg_broker start
#                                in the rman dulicate command
#  3.2  04/2019      R. Ryan     Increased redolog file size check to 10g when overiding logfile size.
#  3.3  04/2019      R. Ryan     Added OEM contact assignment for both database aond listener for Data Center paging.
#  4.0  12/2019      R. Ryan     Added support for container databases
#                                Added create recovery catalog functionality
#  4.1  02/2020      R. Ryan     Enabled cloning from standby databases to create a primary database.
#  4.2  03/2020      R. Ryan     Corrected issue with 18c and above starting an auxiliary database with default SGA size.
#                                Corrected listener definition issue with container databases
#  5.0  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#  5.1  03/2021      R. Ryan     Added section size to support big file tablespaces
#
###########################################################################################################################
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
    log_console "Insufficient free space exists in disk group $DG to complete the clone, ensure there is at least ${space_needed}(GB) available in DATA_01"
    exit 1
  else
    log_console "Disk Group $DG has sufficient free space, continuing with clone......."
  fi
else
  if [ "${DG}" = "+IND_01" ]; then
    log_console "Disk Group +IND_01 does not exist, all files defined in +IND_01 on the target database will be moved to +DATA_01"
    index_dg_missing=true
  else
    log_console "Disk Group $DG is not found, ensure $DG exists before attempting clone."
    exit 1
  fi
fi
}

# Function : Check REDO DG space
check_redo_dg () {

if [ -z "$1" ] ; then
  space_needed=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_redo_space_required.sql $1
eof1`)
  if [ $? -gt 0 ]; then
    log_console "Required space check failed, make sure source database at $SOURCE is available."
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
    export CNT_FILE_3_LOC=${STD_DATA_DG}
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
log_console "Scheduling Purge and Trim Job in OEM"


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
PUPPETPASS=`fetch_db_bt.bash.x -a DBA -r "create standby database" -P puppet -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`


echo target_list=${ORACLE_SID}_${SERVER_NAME}:oracle_database > /tmp/job_prop_$ORACLE_SID.txt

$EMCLI logout | tee -a $LOGFILE
$EMCLI login  -username=oracledba -password=$ORACLEDBAPASS | tee -a $LOGFILE

$EMCLI create_job_from_library -lib_job=PURGE_AND_TRIM_LOGS -name=PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt | tee -a $LOGFILE

if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "Purge and Trim job scheduling failed for ${DB_UNIQUE_NAME},  Please schedule Job manually"
else
  log_console "Purge and Trim job has been scheduled for ${DB_UNIQUE_NAME} with default retentions and log size set in OEM library JOB PURGE_AND_TRIM_LOGS"
  log_console "The Job will starting from today based on the default schedule set in OEM library JOB PURGE_AND_TRIM_LOGS."
  log_console "Reschedule JOB PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} to update the default values."
fi

$EMCLI logout | tee -a $LOGFILE
$EMCLI login  -username=puppet -password=$PUPPETPASS | tee -a $LOGFILE
rm /tmp/job_prop_$ORACLE_SID.txt
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
PUPPETPASS=`fetch_db_bt.bash.x -a DBA -r "create standby database" -P puppet -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`


#$ORACLE_BASE/product/emcli/emcli logout >> $LOGFILE
#$ORACLE_BASE/product/emcli/emcli login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE
if [ "${SOURCE_HOST: -1}" = "p" ] ; then
  case ${SERVER_NAME: -1} in
     p) $EMCLI logout >> $LOGFILE
        $EMCLI login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE
        ;;
     *) log_console "Reconfiguring emcli to point to prod oem from non-prod database server"
        $EMCLI setup -url="https://oemprod.aetna.com/em" -username=oracledba -password=$ORACLEDBAPASS -localdirans=YES -licans=YES -trustall -certans=YES -nocertvalidate -novalidate -autologin | tee -a $LOGFILE 
        $EMCLI sync
        ;;
  esac
else
  case ${SERVER_NAME: -1} in
     p) log_console "Reconfiguring emcli to point to non-prod oem from prod database server"
        $EMCLI setup -url="https://oemdev.aetna.com/em" -username=oracledba -password=$ORACLEDBAPASS -localdirans=YES -licans=YES -trustall -certans=YES -nocertvalidate -novalidate -autologin | tee -a $LOGFILE
        $EMCLI sync
        ;;
     *) $EMCLI logout >> $LOGFILE
        $EMCLI login  -username=oracledba -password=$ORACLEDBAPASS >> $LOGFILE
        ;;
   esac
fi

case $1 in
   suspend)
      log_console "The following Jobs are scheduled or running for the Source database in OEM"
      log_console " "
      $EMCLI get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${SOURCE_DB}_${SOURCE_HOST}:oracle_database | tee -a $LOGFILE
      log_console " "
      $EMCLI $1_job  -owner=ORACLEDBA -targets=${SOURCE_DB}_${SOURCE_HOST}:oracle_database | tee -a $LOGFILE
      ;;
   resume)
      log_console "Resuming source database jobs........"
      $EMCLI $1_job  -owner=ORACLEDBA -targets=${SOURCE_DB}_${SOURCE_HOST}:oracle_database | tee -a $LOGFILE
      log_console "The following Jobs are scheduled or running for the primary database in OEM"
      log_console " "
      $EMCLI get_jobs -status_ids='1;2' -owner=ORACLEDBA -targets=${SOURCE_DB}_${SOURCE_HOST}:oracle_database | tee -a $LOGFILE
      log_console " "
      ;;
esac
RETCD=$?
if [ "${SOURCE_HOST: -1}" = "p" ] ; then
  case ${SERVER_NAME: -1} in
    p) $EMCLI logout >> $LOGFILE
       $EMCLI login  -username=puppet -password=$PUPPETPASS >> $LOGFILE
       ;;
    *) log_console "Reconfiguring emcli to point back to non-prod oem"
       $EMCLI setup -url="https://oemdev.aetna.com/em" -username=puppet -password=$PUPPETPASS -localdirans=YES -licans=YES -trustall -certans=YES -nocertvalidate -novalidate -autologin | tee -a $LOGFILE
       $EMCLI sync
       ;;
  esac
else
  case ${SERVER_NAME: -1} in
    p) log_console "Reconfiguring emcli to point back to prod oem"
       $EMCLI setup -url="https://oemprod.aetna.com/em" -username=puppet -password=$PUPPETPASS -localdirans=YES -licans=YES -trustall -certans=YES -nocertvalidate -novalidate -autologin | tee -a $LOGFILE
       $EMCLI sync
       ;;
    *) $EMCLI logout >> $LOGFILE
       $EMCLI login  -username=puppet -password=$PUPPETPASS >> $LOGFILE
       ;;
  esac
fi

if [ $RETCD -gt 0 ] ; then
  log_console "Job Status Change Failed....."
  log_console " "
  return 1
else
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

ADR_BASE_${ORACLE_SID} = $STD_DBMS_DIR/app/oracle

SID_LIST_${ORACLE_SID} =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLE_SID}_${SERVER_NAME}_dgmgrl)
      (ORACLE_HOME = $STD_DBMS_DIR/app/oracle/product/${VERSION}/db_1)
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

create_app_service () {
#------------------------------------------------------------
# Create Application Service and Service Trigger
#------------------------------------------------------------

#Fetch DB_UNIQUE_NAME services to remove
export SERVICE_NAMES=$LOGDIR/service_names_$ORACLE_SID.log
echo "set echo off ver off pages 0 linesize 180 trims on head off feed off
select listagg(name, '*') within group(order by name) name from dba_services where name not like 'SYS%' and name not like '%_APP' and name not like '%${SERVER_NAME}%';
exit;" | sqlplus -s / as sysdba > $SERVICE_NAMES

export SERVICE_NAMES=$(tail -1 $SERVICE_NAMES |sed -e 's/ //g' | tr '*' ' ')

echo spool \${ORACLE_BASE}/admin/\${ORACLE_SID}/sql/create_service.out >  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql

for SERVICE in  $SERVICE_NAMES
 do
   echo "exec dbms_service.delete_service('${SERVICE}');" >> $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql
 done

cat << label6 >> $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql

exec dbms_service.stop_service('${SOURCE_DB}_APP');
exec dbms_service.delete_service('${SOURCE_DB}_APP');
exec dbms_service.create_service( -
        SERVICE_NAME => '${ORACLE_SID}_APP', -
        NETWORK_NAME => '${ORACLE_SID}_APP', -
        FAILOVER_METHOD => 'BASIC', -
        FAILOVER_TYPE => 'SELECT', -
        FAILOVER_RETRIES => 180, -
        FAILOVER_DELAY => 1);
exec dbms_service.start_service('${ORACLE_SID}_APP', '${ORACLE_SID}');

CREATE OR REPLACE TRIGGER StartDgServices after startup on database
DECLARE
  db_role VARCHAR(30);
  db_open_mode VARCHAR(30);
BEGIN

  execute immediate ' ALTER SYSTEM SET SERVICE_NAMES='' '' ';

  SELECT DATABASE_ROLE, OPEN_MODE INTO db_role, db_open_mode FROM V\$DATABASE;

  IF db_role = 'PRIMARY'
        THEN DBMS_SERVICE.START_SERVICE('${ORACLE_SID}_APP');
  END IF;
  --IF db_role = 'PHYSICAL STANDBY' AND db_open_mode LIKE 'READ ONLY%'
  --      THEN DBMS_SERVICE.START_SERVICE('${ORACLE_SID}_RPT');
  --END IF;
END;
/

spool off;
exit;


label6


cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql > $ORACLE_PATH/runthis.sql

echo Start create service on $ORACLE_SID

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Create application service and trigger failed in sqlplus"
  exit 1
else
  log_console  "Create application service and trigger successful"
fi

rm $ORACLE_PATH/runthis.sql

}
#End of functions

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/clone_db_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [[ $1 == CDB[0-9][0-9]C ]] ; then
  if [ "$#" -lt "2" ]; then
    log_console "Usage: $0  target_db_name source_host redo_log_size_in_megs(optional) num_of_redo_logs(optional)"
    log_console Parms: $*
    exit 1
  else
    log_console "Start $1 Clone  `uname -svrn` at `date` using $0 $*"
  fi
else
  if [ "$#" -lt "5" ]; then
    log_console "Usage: $0  target_db_name target_db_port source_db_name source_db_port source_host redo_log_size_in_megs(optional) num_of_redo_logs(optional)"
    log_console Parms: $*
    exit 1
  else
    log_console "Start Clone $3 to $1  `uname -svrn` at `date` using $0 $*"
  fi
fi

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

case $1 in
  "CDB"[0-9][0-9]"C")
    if [ -z "$3" ]; then
      unset $LOG_SIZE
    else
      LOG_SIZE=$(($3 ))
      case $LOG_SIZE in
         ''|*[!0-9]*) 
            log_console "REDO log size must be numeric, please enter a valid value"
            exit 1 ;;
         *)
            if [ $LOG_SIZE -gt 10000 ] ; then
               log_console "REDO log size is invalid, please enter a vaule between 1 and 10000"
               exit 1
            fi  ;;
      esac
    fi

    if [ -z "$4" ]; then
      unset $LOG_COUNT 
    else
      LOG_COUNT=$4
      case $LOG_COUNT in
         ''|*[!0-9]*) 
            log_console "REDO log size must be numeric, please enter a valid value"
            exit 1 ;;
         *)
            if [ $LOG_COUNT -gt 32 ] ; then
               log_console "REDO log count is invalid, please enter a vaule between 1 and 16"
               exit 1
            fi  ;;
      esac
    fi

    export ORACLE_SID=$1
    export SOURCE_DB=$1
    export SOURCE_HOST=$2
    export SOURCE_PORT=1521
    export LOG_SIZE=$3
    export SOURCE=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$2)(PORT=1521))(CONNECT_DATA=(SID=${SOURCE_DB})))"'"'`
    export PORT=1521
    ;;
  *)
    if [ -z "$6" ]; then
      unset $LOG_SIZE
    else
      LOG_SIZE=$(($6 ))
      case $LOG_SIZE in
         ''|*[!0-9]*) 
            log_console "REDO log size must be numeric, please enter a valid value"
            exit 1 ;;
         *)
            if [ $LOG_SIZE -gt 10000 ] ; then
               log_console "REDO log size is invalid, please enter a vaule between 1 and 10000"
               exit 1
            fi  ;;
      esac
    fi

    if [ -z "$7" ]; then
      unset $LOG_COUNT 
    else
      LOG_COUNT=$7
      case $LOG_COUNT in
         ''|*[!0-9]*) 
            log_console "REDO log size must be numeric, please enter a valid value"
            exit 1 ;;
         *)
            if [ $LOG_COUNT -gt 32 ] ; then
               log_console "REDO log count is invalid, please enter a vaule between 1 and 16"
               exit 1
            fi  ;;
      esac
    fi

    export ORACLE_SID=$1
    export SOURCE_DB=$3
    export SOURCE_HOST=$5
    export SOURCE_PORT=$4
    export LOG_SIZE=$6
    export SOURCE=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$5)(PORT=$4))(CONNECT_DATA=(SID=${SOURCE_DB})))"'"'`
    export PORT=$2
    ;;
esac

export EMCLI=$ORACLE_BASE/product/emcli/emcli

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
  log_console "Invalid Password, try again or $SOURCE_DB is not available, check $LOGFILE for details"
  exit 1
else
  log_console "Log on successful, continuing with clone....."
fi
log_console " "

#----------------------------------------------------------------------------
# Check if data and index diskgroup exist and have adequate space
#----------------------------------------------------------------------------
export ORACLE_SID=+ASM
export ORAENV_ASK=NO

. oraenv >> $LOGFILE

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

log_console " "

#--------------------------------------------------------------------
# Check to ensure archive log disk group exists
#-------------------------------------------------------------------
DG1=`echo $STD_ARCHIVE_LOG_DG | tr -d +`
freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'$DG1'" 
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi

if [ ${freespace[0]} -eq 1 ]; then
  log_console "Disk Group ${STD_ARCHIVE_LOG_DG} exists, continuing with clone......."
else
  log_console "Disk Group ${STD_ARCHIVE_LOG_DG} is not found, ensure ${STD_ARCHIVE_LOG_DG} exists before attempting clone."
  exit 1
fi
log_console " "

#----------------------------------------------------------------------------
# Check if REDO Disk Groups exist and have adequate space
#----------------------------------------------------------------------------
if [ -z "$LOG_SIZE" ] || [ "$LOG_SIZE" = "0" ]; then
  log_console "REDO log size was not secified, the vaule will be fetched from the source database"
  LOG_SIZE=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_log_size.sql 
eof1`)
  if [ $? -gt 0 ]; then
    log_console "Log size fetch failed, make sure source database at $SOURCE is available."
    exit 1
  fi
fi

if [ -z "$LOG_COUNT" ] ; then
  log_console "REDO log count was not secified, the vaule will be fetched from the source database"
  LOG_COUNT=(`sqlplus -s sys/$password@$SOURCE as sysdba<<eof1
@get_log_number.sql 
eof1`)
  if [ $? -gt 0 ]; then
    log_console "Log number fetch failed, make sure source database at $SOURCE is available."
    exit 1
  fi
fi

space_needed=$(($LOG_COUNT * $LOG_SIZE))   

log_console " "

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
    if [ "${DG}" = "+REDOC_01" ]; then
      export CNT_FILE_3_LOC=+REDOC_01
    fi
    check_redo_dg $DG $space_needed
  done

if [ "${CNT_FILE_3_LOC}" != "+REDOC_01" ]; then
  export CNT_FILE_3_LOC=${STD_DATA_DG}
fi

log_console " "


export ORACLE_SID=$1
#export PORT=$2

#----------------------------------------------------------------------------------
# Fetch Version from Primary database
#----------------------------------------------------------------------------------
export MAJ_REL=$LOGDIR/major_rel_$1.log
echo "set echo off ver off pages 0 trims on head off feed off
select substr(version,1,2) from v\$instance;
exit;" | sqlplus -s "sys/$password@$SOURCE" as sysdba > $MAJ_REL

export MAJ_REL=$(tail -1 $MAJ_REL |sed -e 's/ //g' | cut -d ' ' -f1)

export VERSION=$LOGDIR/version_$1.log

echo "set echo off ver off pages 0 trims on head off feed off
select REGEXP_SUBSTR (SYS_CONTEXT ('USERENV','ORACLE_HOME'), '[0-9]+[.][0-9]+[.][0-9]+') from dual
exit;" | sqlplus -s "sys/$password@$SOURCE" as sysdba > $VERSION

export VERSION=$(tail -1 $VERSION |sed -e 's/ //g' | cut -d ' ' -f1)
#export TNS_ADMIN=/orahome/u01/app/oracle/product/$VERSION/db_1/network/admin

log_console "Source database $SOURCE_DB is at PSU level $VERSION"

if [ -d $STD_DBMS_DIR/app/oracle/product/${VERSION} ]; then
  log_console "Oracle DBMS software version $VERSION is installed, continuing with clone........"
else
  log_console "Oracle DBMS software version $VERSION is not installed."
  exit 1
fi

if [ -d $STD_DBMS_DIR/app/oracle/product/$VERSION/db_1/nls/data/9idata ] ; then
  log_console "E-Business Suite Oracle Home has been detected"
  log_console "Database will be created from the E-Business Suite Standard Build"
  ps -ef | grep pmon | grep -v +ASM | grep -v grep >/dev/null
  if test $? -eq 0; then
    log_console "The following databases have been found to be executing on this VM:"
    log_console "`ps -ef | grep pmon | grep -v +ASM | grep -v grep`"
    log_console "Only one database per VM is permitted for E-Business Suite systems"
    exit 1
  fi
fi

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


if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] ; then
  echo
else
  netstat -tlen | grep :$PORT >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    log_console "Selected port is in use, please free the port or select another"
    exit 1
  fi
fi

ORATAB=/etc/oratab
grep $ORACLE_SID $ORATAB >/dev/null | grep -v $ORACLE_SID[0-z] | grep -v ${ORACLE_SID}_del 2>&1
if [ $? -eq 0 ]; then
  log_console "Database already exists in ORATAB, drop/remove it before attempting clone"
  exit 1
else
  log_console "Adding ORATAB entry"
  echo $ORACLE_SID:$STD_DBMS_DIR/app/oracle/product/$VERSION/db_1:N >> $ORATAB
fi 

#---------------------------------------------------------------------------
#  Check for sufficient free huge pages to accomodate source SGA
#---------------------------------------------------------------------------
export SGA_MAX_SIZE=2147483648

FREE_HUGE_PAGES=(`grep HugePages_Free /proc/meminfo | awk ' {print $2} '`)

if [ $(($FREE_HUGE_PAGES*2097152)) -lt $(($SGA_MAX_SIZE)) ]; then
   log_console "Free Huge Pages: $FREE_HUGE_PAGES"
   log_console "Free Huge Pages required to accmodate a $SGA_MAX_SIZE byte sga: $(($SGA_MAX_SIZE/2097152))"
   log_console "Insufficient Huge Pages allocated to accomodate the new database"
   exit 1
fi


#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

export ORAENV_ASK=NO
. oraenv >> $LOGFILE

export PATH=$ORACLE_HOME/bin:$PATH

#------------------------------------------------------------
#  Build/Start Database Instance
#------------------------------------------------------------

mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/rman
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql

echo DB_NAME=$ORACLE_SID > $ORACLE_HOME/dbs/init_for_clone.pfile
echo SGA_TARGET=2G >>  $ORACLE_HOME/dbs/init_for_clone.pfile
$ORACLE_HOME/bin/orapwd file=$ORACLE_HOME/dbs/orapw${ORACLE_SID} password=$password entries=10 

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

#------------------------------------------------------------
# Configure Listener 
#------------------------------------------------------------

export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`

if [ -z ${CONTEXT_NAME+x} ]; then 
  echo
else
  mkdir -p $TNS_ADMIN
  cp $ORACLE_HOME/network/admin/ldap.ora $TNS_ADMIN
  cp $ORACLE_HOME/network/admin/sqlnet.ora $TNS_ADMIN
fi

if [[ $ORACLE_SID != CDB[0-9][0-9]C ]] ; then
#  GI_RELEASE=`grep +ASM /etc/oratab | cut -d / -f7`
#  cp -p /orastage/u177/CDB_ASM_listener.ora $TNS_ADMIN/listener.ora
#  perl -i -pe "s/<host_name>/$HOSTNAME/g" $TNS_ADMIN/listener.ora
#  perl -i -pe "s/<dbms_release>/$VERSION/g" $TNS_ADMIN/listener.ora
#  perl -i -pe "s/<cdb_sid>/$ORACLE_SID/g" $TNS_ADMIN/listener.ora
#  perl -i -pe "s/<gi_release>/$GI_RELEASE/g" $TNS_ADMIN/listener.ora
#  lsnrctl stop listener
#  lsnrctl start listener
#else
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
# Configure TNS entry
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
  grep -i ${SOURCE_DB}_${SOURCE_HOST} $TNS_ADMIN/tnsnames.ora >/dev/null
    if [ $? -gt 0 ] ; then
    log_console "Adding source database TNS entry"
    add_tns_entry ${SOURCE_DB} ${SOURCE_HOST} ${SOURCE_PORT} 
  else
    log_console "Source database TNS entry exists"
  fi
else
  add_tns_entry ${ORACLE_SID} ${SERVER_NAME} ${PORT}
  add_tns_entry ${SOURCE_DB} ${SOURCE_HOST} ${SOURCE_PORT}
fi

if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] ; then
  echo
else
  if [ "$MAJ_REL" == "11" ] ; then
    srvctl add listener -l $ORACLE_SID -o $ORACLE_HOME -p "TCP:${PORT}/IPC:${ORACLE_SID}_IPC" >>$LOGFILE 
    if [ $? -gt 0 ] ; then
      log_console "ERROR ---> srvctl add listener failed!!!"
      exit 1
    fi
  else
    srvctl add listener -l $ORACLE_SID -oraclehome $ORACLE_HOME -endpoints "TCP:${PORT}/IPC:${ORACLE_SID}_IPC" >>$LOGFILE 
    if [ $? -gt 0 ] ; then
      log_console "ERROR ---> srvctl add listener failed!!!"
      exit 1
    fi
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

cat << label3 >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd

duplicate target database to '${ORACLE_SID}'
from active database
logfile
label3

#for ((i=1;i<LOG_COUNT;i++));
#  do
#    echo "GROUP ${i} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M," >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#  done

#echo "GROUP ${LOG_COUNT} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd

echo "GROUP 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M," >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
echo "GROUP 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M" >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd

cat <<label3a >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
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
set sga_target='2g'
set sga_max_size='2g'
set log_archive_dest_2=''
set log_archive_dest_3=''
set log_archive_dest_4=''
reset instance_name
reset log_archive_config
reset fal_server
reset dg_broker_start
label3a

if [ $redoc_missing ]; then
  cat <<label3b >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
set db_create_online_log_dest_3=' '
label3b
fi

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
echo >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
if [ "$MAJ_REL" > "12" ] ; then
  echo set \"_disk_sector_size_override\"=\'true\' >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
fi
echo 'nofilenamecheck;' >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
echo } >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
 
#case ${#DATA_DG[@]} in
#1)
#cat <<label4a >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#set db_file_name_convert '+DATA_01','${DATA_DG[0]}'
#nofilenamecheck;
#}
#label4a
#;;
#2)
#if [ ${DATA_DG[2]} =~ "IND" ]; then
#  cat <<label4b >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#  set db_file_name_convert  '+DATA_01','${DATA_DG[0]}','+IND_01','${DATA_DG[1]}'
#  nofilenamecheck;
#  }
#label4b
#else
#  cat <<label4b >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#  set db_file_name_convert  '+DATA_01','${DATA_DG[0]}','+DATA_02','${DATA_DG[1]}'
#  nofilenamecheck;
#  }
#label4b
#;;
#3)
#cat <<label4c >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#set db_file_name_convert '+DATA_01','${DATA_DG[0]}','+DATA_02','${DATA_DG[1]}','+DATA_03','${DATA_DG[2]}','+IND_01','${INDEX_DG}'
#nofilenamecheck;
#}
#label4c
#;;
#esac

rman_loc=$ORACLE_BASE/admin/$ORACLE_SID/rman
rman_job=duplicate_$SOURCE_DB
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
echodo rman target sys/$password@${SOURCE_DB}_${SOURCE_HOST} \
auxiliary sys/$password@${ORACLE_SID}_${SERVER_NAME} \
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
  change_job_status resume
else
  echo Including rman duplicate log..... >> $LOGFILE
  cat ${rman_logfile} >> $LOGFILE
  echo ========== End of rman duplicate log ============ >> $LOGFILE
  log_console "RMAN Duplicate Failed!!!"
  log_console "Attempting to drop database $ORACLE_SID......"
  dbca -silent -deleteDatabase -sysPassword $password -sourceDB $ORACLE_SID | tee -a $LOGFILE
  log_console "Drop of database $ORACLE_SID complete"
  log_console "Removing listener $ORACLE_SID"
  srvctl stop listener -l $ORACLE_SID | tee -a $LOGFILE
  srvctl remove listener -l $ORACLE_SID | tee -a $LOGFILE
  log_console "Listener $ORACLE_SID has been removed"
  log_console "Restoring network configuration files"
  if [ -f $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR ] ; then
    cp $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR $ORACLE_HOME/network/admin/tnsnames.ora
  else
    rm  $ORACLE_HOME/network/admin/tnsnames.ora
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
  change_job_status resume
  exit 1
fi

#-----------------------------------------------------------
# Create redo logs with 4k block size
#-----------------------------------------------------------
log_console " "
log_console "Re-creating REDO log groups with 4k block size.............."
echo "shutdown immediate;" | sqlplus / as sysdba >> $LOGFILE
echo "startup;" | sqlplus / as sysdba >> $LOGFILE
echo "alter database add logfile group 3 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE

export CURRENT_DG=${LOGDIR}/CURRENT_DG_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off 
select group# from v\$log where status='CURRENT';
exit;" |  sqlplus -s / as sysdba > $CURRENT_DG

export CURRENT_DG=$(tail -1 $CURRENT_DG |sed 's/\s*$//g' | tr -d " ")

if [ "${CURRENT_DG}" -eq "1" ]; then
  echo "alter database drop logfile group 2;" | sqlplus / as sysdba >> $LOGFILE 
  echo "alter database add logfile group 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter system switch logfile;" | sqlplus / as sysdba  >> $LOGFILE
  echo "shutdown immediate;" | sqlplus / as sysdba  >> $LOGFILE
  echo "startup;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database drop logfile group 1;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
elif [ "${CURRENT_DG}" -eq "2" ]; then
  echo "alter database drop logfile group 1;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter system switch logfile;" | sqlplus / as sysdba >> $LOGFILE
  echo "shutdown immediate;" | sqlplus / as sysdba >> $LOGFILE
  echo "startup;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database drop logfile group 2;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE 
else
  log_console "Invalid Current log group returned"
fi

for ((i=4;i<=LOG_COUNT;i++));
  do
    echo "GROUP ${i} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M," >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
    echo "alter database add logfile group ${i} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba 
  done

log_console "REDO log re-creation complete"
log_console "RDOO log configuration is as follows:"

echo "select group#, bytes, blocksize from v\$log;" | sqlplus -s / as sysdba | tee -a $LOGFILE
    

#------------------------------------------------------------
#Add database to HAS
#------------------------------------------------------------

if [ "$MAJ_REL" == "11" ] ; then
  srvctl add database -d ${ORACLE_SID}_${SERVER_NAME} -o ${ORACLE_HOME} -p ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora -i ${ORACLE_SID} -a "${STD_DATA_DG:1},${STD_REDO1_DG:1},${STD_REDO2_DG:1}" | tee -a $LOGFILE
  srvctl start database -d ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
else
  srvctl add database -db ${ORACLE_SID}_${SERVER_NAME} -oraclehome ${ORACLE_HOME} -spfile ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora -instance ${ORACLE_SID} -diskgroup "${STD_DATA_DG:1},${STD_REDO1_DG:1},${STD_REDO2_DG:1}" | tee -a $LOGFILE
  srvctl setenv database -db ${ORACLE_SID}_${SERVER_NAME} -env "TNS_ADMIN=$TNS_ADMIN" | tee -a $LOGFILE
  srvctl stop  database -db ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
  srvctl start  database -db ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
fi



#------------------------------------------------------------
# Create symbolic link from $ORACLE_BASE/admin/$ORACLE_SID
# to $ORACLE_HOME to suuport Gardium and the viloin agent
#------------------------------------------------------------

log_console " "
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

#------------------------------------------------------------
# Create Application Service and Service Trigger
#------------------------------------------------------------

if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] ; then
  log_console "The database has been identified as a container, skipping application service creation"
else
  create_app_service
fi

#-------------------------------------------------------------
# Remove Audit Trail timestamps for old dbids
#-------------------------------------------------------------
case  $ORACLE_SID in
  CDB[0-9][0-9]C)
    log_console "The database has been identified as a container, there is no action to take reguarding audit timestamps for CDBs"
  ;;
  *)
    export DB_ID_LIST=$LOGDIR/db_id_list_$PRIMARY_DB.log
    echo "set echo off ver off pages 0 trims on head off feed off
    select unique database_id from DBA_AUDIT_MGMT_LAST_ARCH_TS minus select dbid from v\$database;
    exit;" | sqlplus -s /  as sysdba > $DB_ID_LIST

    export DB_ID_LIST=$(tail -1 $DB_ID_LIST |sed -e 's/ //g')
    log_console " "
    log_console "List Of Audit Trail timestamp DB_IDs to delete: $DB_ID_LIST"

    for DBID in $DB_ID_LIST
      do
        log_console "Removing audit trail timestamps for DBID $DBID"
        sqlplus -S / as sysdba <<EOF >> $LOGFILE
        whenever sqlerror exit failure 1
        exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,DATABASE_ID=>$DBID);
        exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,DATABASE_ID=>$DBID);
        exit;
EOF
        if [ $? -gt 0 ] ; then
          log_console "Error -----> Removal of audit trail timestamp for $DBID failed"
        else
          log_console "Removal of audit trail timestamps for $DBID successful"
        fi
      done
   ;;
esac


#-------------------------------------------------------------
# Remove AWR data for old DBIDs and set 30 retention
#-------------------------------------------------------------
log_console " "
log_console "Removing old AWR DBIDs and set snap shot retention to 30 days"

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@remove_old_awr_dbids.sql
EXECUTE DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(retention => 43200);
exit;
EOF
    
if [ $? -gt 0 ] ; then
   log_console "Error -----> AWR updates failed"
   log_console "The failure is expected on database releases prior to 12.1.0.170718 due to a bug fixed in the July 2017 PSU"
   log_console "Execute $SQLPATH/remove_old_awr_dbids.sq after the database is upgraded to at least 12.1.0.2.170718"
   log_console "to remove old AWR DBID's"
else
   log_console "AWR updates successful"
fi

#-------------------------------------------------------------
# Remove non-seed PDBs from container database
#-------------------------------------------------------------
#if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] ; then
#  log_console "The database has been identified as a container, dropping non-seed PDBs......." 
#  export PDB_LIST=$LOGDIR/pdb_list_$ORACLE_SID.log
#  echo "set echo off ver off pages 0 trims on head off feed off
#  select listagg(pdb_name,'_') within group (order by pdb_name) names from dba_pdbs where pdb_name <> 'PDB\$SEED';
#  exit;" | sqlplus -s /  as sysdba > $PDB_LIST
#
#  export PDB_LIST=$(tail -1 $PDB_LIST |sed -e 's/ //g' | tr '_' ' ')
#  log_console " "
#  log_console "List Of PDBs to delete: $PDB_LIST"
#
#  for PDB in $PDB_LIST
#    do
#      log_console "Removing PDB $PDB"
#      sqlplus -S / as sysdba <<EOF >> $LOGFILE
#      whenever sqlerror exit failure 1
#      alter pluggable database $PDB close immediate;
#      drop pluggable database $PDB including datafiles;
#      exit;
#EOF
#      if [ $? -gt 0 ] ; then
#        log_console "Error -----> Removal of PDB $PDB failed"
#      else
#        log_console "Removal of PDB $PDB successful"
#      fi
#    done
#  log_console "Removal of non-seed PDBs is complete"
#fi


#-------------------------------------------------------------
# Enable Block Change Tracking
#-------------------------------------------------------------
log_console " "
log_console "Enabling Block Change Tracking"
sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
set linesize 160
col STATUS format a12
col FILENAME format a80
ALTER DATABASE ENABLE BLOCK CHANGE TRACKING;
SELECT status, filename FROM V\$BLOCK_CHANGE_TRACKING; 
exit;
EOF
if [ $? -gt 0 ] ; then
  log_console "Error -----> Enable Block Change Tracking failed"
else
  log_console "Block Change Tracking has been enabled"
fi


#----------------------------------------------------------
#  Add database to OEM
#----------------------------------------------------------
log_console " "
log_console "Starting OEM update........."

if [ -x $ORACLE_BASE/product/emcli/emcli ] ; then
  log_console " emcli exists and is executable, updating OEM"
  log_console " "
  $EMCLI add_target -name="${ORACLE_SID}_${SERVER_NAME}" -type="oracle_database" -host="$HOSTNAME" -credentials="UserName:dbsnmp;password:drugs2gogo;Role:normal" -properties="SID:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};MachineName:$HOSTNAME" -groups="Unassigned:composite" 
  case $? in
    [1-5]|[7-23]|[219-223]*) log_console "OEM Database Target add has failed!!!  Please add database to OEM manually" ;;
    6) log_console "OEM database target already exists in OEM, this is expected on a database refresh" ;;
    *) $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Comment:Standard Build"
       $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Contact:(Oracle DBA)"
       schedule_purge;;
  esac
  if [[ $1 == CDB[0-9][0-9]C ]] ; then
    echo 
  else
    $EMCLI add_target -name="${ORACLE_SID}_${HOSTNAME}" -type="oracle_listener" -host="$HOSTNAME"  -properties="LsnrName:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};ListenerOraDir:${TNS_ADMIN};Machine:$HOSTNAME" -groups="Unassigned:composite" 
    case $? in
      [1-5]|[7-23]|[219-223]*) log_console "OEM Listener Target add has failed!!!  Please add listener to OEM manually" ;;
      6) log_console "OEM  listener target already exists in OEM, this is expected on a database refresh" ;;
      *) $EMCLI set_target_property_value -property_records="${ORACLE_SID}_${HOSTNAME}:oracle_listener:Contact:(Oracle DBA)" ;;
    esac
  fi
else
  log_console "emcli is not installed on this server, please add database to OEM manually"
fi

#----------------------------------------------------------
#  Create recovery catalog and register database
#----------------------------------------------------------
create_rcat.sh $ORACLE_SID | tee -a $LOGFILE

log_console " "
log_console "Create clone of $3  to  $1 complete  `uname -svrn` at `date` using $0 "
log_console " "
log_console "Note!!  The SGA size of $ORACLE_SID has been set to the defaut vaule of 2GB. Adjust this setting as needed"
echo 


exit 0

