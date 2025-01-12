#!/bin/bash
################################################################################
# Shell Script : purge_trim_logs.sh                                            #
# Created By   : Tim Long                                                      #
# Created On   : 3/29/2011   Modified: 8/26/2015                               #
# VERSION      : 1.2                                                           #
# Overview     : Shell script to purge .aud files, .trc files and core dumps   #
#                from adump, bdump, cdump and udump directories that exceed    #
#                maximum age in days as set in DBCMS.DBMON_CONFIG table.       #
#                Trim alert log if exceeds maximum size in bytes as set in     #
#                DBCMS.DBMON_CONFIG table.                                     #
#                The trimmed alert logs are added to self-purging monthly      #
#                tar files.                                                    #
#                If database is 11g version, this script invokes ADRCI         #
#                to purge ADR contents that exceed maximum age in days as set  #
#                in the DBCMS.DBMON_CONFIG table.                              #
################################################################################

log_console () {
  echo "$*" | tee -a $LOGFILE
}


. ~/.bash_profile >/dev/null 2>/dev/null
source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/purge_trim_logs_$1_$DATEVAR.out
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE


if [ $# -ne 5 ]; then
  log_console "Usage: $0 target_db_name aud_ret trace_ret inc_ret alert_log_size " 
  log_console Parms: $*
  exit 1
fi

if [ "$2" -eq "$2" ] 2>/dev/null; then
  echo $2 >/dev/null
else
  log_console "Audit Retention must be numeric"
  exit 1
fi

if [ "$3" -eq "$3" ] 2>/dev/null; then
  echo $2 >/dev/null
else
  log_console "Trace file Retention must be numeric"
  exit 1
fi

if [ "$4" -eq "$4" ] 2>/dev/null; then
  echo $2 >/dev/null
else
  log_console "Incident Retention must be numeric"
  exit 1
fi

if [ "$5" -eq "$5" ] 2>/dev/null; then
  echo $2 >/dev/null
else
  log_console "Alert Log Size must be numeric"
  exit 1
fi


export ORACLE_SID=$1

grep $ORACLE_SID $ORATAB >/dev/null 2>&1
if [ $? -ne 0 ]; then
  log_console "Specified Database SID is invalid"
  exit 1
fi

export ORAENV_ASK=NO
. /usr/local/bin/oraenv >> $LOGFILE

# Set up script logfile
v_this_script_name=`basename $0`
v_aud_ret=$2
v_trace_ret=$3
v_inc_ret=$4
v_alert_size=$5

v_output_log_retention_period=360
v_output_log_dest=$LOGDIR
v_normal_log_file=$LOGFILE
v_sql_log_file=${v_output_log_dest}/sql.log
v_12g_version=`echo $ORACLE_HOME | cut -d / -f7 | cut -d . -f1`
v_server=`echo $HOSTNAME | cut -d . -f1`
v_return_code=$?
printf "=============================================================================\n" >> $v_normal_log_file
printf "=                          $v_this_script_name Log \n" >> $v_normal_log_file
printf "=\n" >> $v_normal_log_file
printf "=                        `date '+%m/%d/%y %X %A '`\n" >> $v_normal_log_file
printf "=\n" >> $v_normal_log_file
printf "=                        Max .aud file age: $v_aud_ret days\n" >> $v_normal_log_file
printf "=                        Max .trc file age: $v_trace_ret days\n" >> $v_normal_log_file
printf "=                        Max core dump age: $v_trace_ret days\n" >> $v_normal_log_file
printf "=                       Max Alert log size: $v_alert_size bytes\n" >> $v_normal_log_file
printf "=============================================================================\n" >> $v_normal_log_file

# Clean old script logfiles
find $v_output_log_dest -name "$ORACLE_SID_${v_this_script_name}*" -type f -mtime +${v_output_log_retention_period} -print -exec rm {} \; 2>/dev/null
# Clean old Tidal logs
find $v_output_log_dest -type f \( -name "*"  \) -mtime +${v_output_log_retention_period} -print -exec rm {} \; 2>/dev/null

if [ $ORACLE_SID = '+ASM' ] ; then
  # Get count of .aud files to purged
  v_aud_file_count=`find $ORACLE_HOME/rdbms/audit -name "*.aud" -type f -print | wc -l`
  v_aud_file_count=`echo $v_aud_file_count`
  v_to_be_purged_count=`find $ORACLE_HOME/rdbms/audit -name "*.aud" -type f -mtime +${v_aud_ret} -print | wc -l`
  v_to_be_purged_count=`echo $v_to_be_purged_count`
else
  # Get count of .aud files to purged
  v_aud_file_count=`find $STD_ADMP_DIR/$ORACLE_SID/adump -name "*.aud" -type f -print | wc -l`
  v_aud_file_count=`echo $v_aud_file_count`
  v_to_be_purged_count=`find $STD_ADMP_DIR/$ORACLE_SID/adump -name "*.aud" -type f -mtime +${v_aud_ret} -print | wc -l`
  v_to_be_purged_count=`echo $v_to_be_purged_count`
fi


# Send file counts to log file prior to purging
printf "There are $v_aud_file_count total .aud files.\n" >> $v_normal_log_file
printf "There are $v_to_be_purged_count .aud files older than $v_aud_ret days that will be purged.\n" >> $v_normal_log_file

if  [ $ORACLE_SID = '+ASM' ] ; then
  # Purge .aud files
  aud_status='X'
  find $ORACLE_HOME/rdbms/audit -name "*.aud" -type f -mtime +${v_aud_ret} -print -exec rm -f {} \; >/dev/null 2>&1
else 
  aud_status='X'
  find $STD_ADMP_DIR/$ORACLE_SID/adump -name "*.aud" -type f -mtime +${v_aud_ret} -print -exec rm -f {} \; >/dev/null 2>&1
fi
  # Error checking
if [ $v_return_code -ne 0 ]
then
    printf "Error encountered when purging .aud files!!!\n" >> $v_normal_log_file
    aud_status='F'
else
    printf "$v_to_be_purged_count .aud files have been purged.\n" >> $v_normal_log_file
    if [  $v_to_be_purged_count -eq 0 ]
    then
      aud_status='X'
    else
      aud_status='S'
    fi
fi

# Get alert log size
#if [ $ORACLE_SID = '+ASM' ] ; then
#  v_alert_log_size=`ls -l $STD_GRID_DIR/app/base/diag/asm/$DB_UNIQUE_NAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log | tr -s " " | cut -d " " -f 5`
#else
#  v_alert_log_size=`ls -l $STD_DBMS_DIR/app/$STD_ORA_USER/diag/rdbms/$DB_UNIQUE_NAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log | tr -s " " | cut -d " " -f 5`
#fi
v_alert_log_size=`ls -l $BDUMP/alert_$ORACLE_SID.log | tr -s " " | cut -d " " -f 5`
printf "$ORACLE_SID alert log size is ${v_alert_log_size} bytes.\n" >> $v_normal_log_file

# Get listener log size
if [ $ORACLE_SID = '+ASM' ] ; then
  v_listener_name=listener
else
  v_listener_name=`echo $ORACLE_SID | tr '[:upper:]' '[:lower:]'`
fi
if [ -f $LSNRLOG/${v_listener_name}.log ] ; then
  v_listener_log_size=`ls -l $LSNRLOG/${v_listener_name}.log | tr -s " " | cut -d " " -f 5`
  printf "$ORACLE_SID listener log size is ${v_listener_log_size} bytes.\n" >> $v_normal_log_file
fi

# Trim alert log if needed
alert_status='X'
if [ $v_alert_log_size -ge $v_alert_size ]
then
   printf "Alert log exceeds $v_alert_size bytes and will be trimmed and archived.\n" >> $v_normal_log_file
   v_arc_alert_log=alert_$ORACLE_SID.log.`date '+%Y%m%d%H%M'`
   export v_arc_alert_log
   cat $BDUMP/alert_$ORACLE_SID.log > $BDUMP/${v_arc_alert_log}
   cat /dev/null > $BDUMP/alert_$ORACLE_SID.log
   if [ $v_return_code -ne 0 ]
   then
     printf "Error encountered when trimming alert log!\n" >> $v_normal_log_file
     alert_status='F'
   else
     alert_status='S'
   fi
   v_arc_alert_logs=${ORACLE_SID}_alert_logs_tar.`date '+%m'`.tar
   gzip $BDUMP/${v_arc_alert_log}
   if [ -f $BDUMP/${v_arc_alert_logs} ] 
   then
     tar -uf $BDUMP/${v_arc_alert_logs} $BDUMP/${v_arc_alert_log}.gz
     printf "$ORACLE_SID Alert log has been trimmed and archived in existing ${v_arc_alert_logs} tarfile.\n" >> $v_normal_log_file
   else
     tar -cf $BDUMP/${v_arc_alert_logs} $BDUMP/${v_arc_alert_log}.gz
     printf "$ORACLE_SID Alert log has been trimmed and archived in new ${v_arc_alert_logs} tarfile.\n" >> $v_normal_log_file
   fi
   rm -f $BDUMP/${v_arc_alert_log}.gz
else
   printf "Alert log smaller than 10240000 bytes...trimming will be deferred until it reaches at least 10240000 bytes.\n" >> $v_normal_log_file
fi

# Trim listener log if needed
alert_status='X'
if [ -f $LSNRLOG/${v_listener_name}.log ] ; then
  if [ $v_listener_log_size -ge $v_alert_size ]
  then
     printf "Listener log exceeds $v_alert_size bytes and will be trimmed and archived.\n" >> $v_normal_log_file
     v_arc_listener_log=${v_listener_name}.log.`date '+%Y%m%d%H%M'`
     export v_arc_listener_log
     cat $LSNRLOG/${v_listener_name}.log > $LSNRLOG/${v_arc_listener_log}
     cat /dev/null > $LSNRLOG/${v_listener_name}.log
     if [ $v_return_code -ne 0 ]
     then
       printf "Error encountered when trimming listner log!\n" >> $v_normal_log_file
       alert_status='F'
     else
       alert_status='S'
     fi
     v_arc_listener_logs=${v_listener_name}_logs_tar.`date '+%m'`.tar
     gzip $LSNRLOG/${v_arc_listener_log}
     if [ -f $LSNRLOG/${v_arc_listener_logs} ]
     then
        tar -uf $LSNRLOG/${v_arc_listener_logs} $LSNRLOG/${v_arc_listener_log}.gz
        printf "$ORACLE_SID Listener log has been trimmed and archived in existing ${v_arc_listener_logs} tarfile.\n" >> $v_normal_log_file
     else
       tar -cf $LSNRLOG/${v_arc_listener_logs} $LSNRLOG/${v_arc_listener_log}.gz
       printf "$ORACLE_SID Listener log has been trimmed and archived in new ${v_arc_listener_logs} tarfile.\n" >> $v_normal_log_file
     fi
     rm -f $LSNRLOG/${v_arc_listener_log}.gz
  else
     printf "Listener log smaller than 10240000 bytes...trimming will be deferred until it reaches at least 10240000 bytes.\n" >> $v_normal_log_file
  fi
fi

# Generate alert log error log
v_alert_err_file=${v_output_log_dest}/${ORACLE_SID}_error.log
#if [ $ORACLE_SID = '+ASM' ] ; then
#  cat $STD_GRID_DIR/app/base/diag/asm/$DB_UNIQUE_NAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log | sed -n '/ORA-/p' > ${v_alert_err_file}
#else
#  cat $STD_DBMS_DIR/app/$STD_ORA_USER/diag/rdbms/$DB_UNIQUE_NAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log | sed -n '/ORA-/p' > ${v_alert_err_file}
#fi
cat $BDUMP/alert_$ORACLE_SID.log | sed -n '/ORA-/p' > ${v_alert_err_file}


  printf "\n" >> $v_normal_log_file
  printf "=============================================================================\n" >> $v_normal_log_file
  printf "=        adrci purge started at `date`\n" >> $v_normal_log_file
  printf "=============================================================================\n" >> $v_normal_log_file
  printf "\n" >> $v_normal_log_file
  adrci_home=1
  ${ORACLE_HOME}/bin/adrci exec="show homes"|grep -v : | while read LINE
  do
    v_dbname=`echo $LINE | sed 's/.*[/]//'`
    if [ `echo $v_dbname | tr '[:upper:]' '[:lower:]'` = `echo $ORACLE_SID | tr '[:upper:]' '[:lower:]'` ] || [ $ORACLE_SID = '+ASM' -a $v_dbname = 'listener' ]
    then
      adrci_home=0
      printf "INFO: adrci purging diagnostic destination $LINE\n" >> $v_normal_log_file
      printf "INFO: purging ALERT older than $v_trace_ret days\n" >> $v_normal_log_file
      age_minutes=`expr ${v_trace_ret} \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type ALERT"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging ALERT!!!\n" >> $v_normal_log_file
        alert_age='F'
      else
        printf "ALERT xml logs have been purged.\n" >> $v_normal_log_file
        alert_age='S'
      fi
      printf "INFO: purging TRACE older than ${v_trace_ret} days\n" >> $v_normal_log_file
      age_minutes=`expr ${v_trace_ret} \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type TRACE"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging TRACE!!!\n" >> $v_normal_log_file
        trace_status='F'
      else
        printf "TRACE trace files have been purged.\n" >> $v_normal_log_file
        trace_status='S'
      fi
      printf "INFO: purging CDUMP older than ${v_trace_ret} days\n" >> $v_normal_log_file
      age_minutes=`expr ${v_trace_ret} \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type CDUMP"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging CDUMP!!!\n" >> $v_normal_log_file
        core_status='F'
      else
        printf "CDUMP core dump files have been purged.\n" >> $v_normal_log_file
        core_status='S'
      fi
      printf "INFO: purging UTSCDMP older than 14 days\n" >> $v_normal_log_file
      age_minutes=`expr 14 \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type UTSCDMP"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging UTSCDMP!!!\n" >> $v_normal_log_file
        coredir_status='F'
      else
        printf "UTSCDMP core dump directories have been purged.\n" >> $v_normal_log_file
        coredir_status='S'
      fi
      printf "INFO: purging HM older than 90 days\n" >> $v_normal_log_file
      age_minutes=`expr 90 \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type HM"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging HM!!!\n" >> $v_normal_log_file
        hm_status='F'
      else
        printf "HM health monitor files have been purged.\n" >> $v_normal_log_file
        hm_status='S'
      fi
      printf "INFO: purging Incidents older than $v_inc_ret days\n" >> $v_normal_log_file
      age_minutes=`expr ${v_inc_ret} \* 1440`
      ${ORACLE_HOME}/bin/adrci exec="set homepath $LINE;purge -age $age_minutes -type INCIDENT"
      # Error checking
      if [ $v_return_code -ne 0 ]
      then
        printf "Error encountered when purging incidents!!!\n" >> $v_normal_log_file
        in_status='F'
      else
        printf "Incident files have been purged.\n" >> $v_normal_log_file
        in_status='S'
      fi
      # Purge CRS trace files
      if [ $ORACLE_SID = '+ASM' ] ; then
        printf "INFO: purging CRS TRACE older than ${v_trace_ret} days\n" >> $v_normal_log_file
        age_minutes=`expr ${v_trace_ret} \* 1440`
        CRS_HOME=`${ORACLE_HOME}/bin/adrci exec="show homes"|grep crs`
        ${ORACLE_HOME}/bin/adrci exec="set homepath $CRS_HOME;purge -age $age_minutes -type TRACE"
        # Error checking
        if [ $v_return_code -ne 0 ]
        then
          printf "Error encountered when purging TRACE!!!\n" >> $v_normal_log_file
          trace_status='F'
        else
          printf "CRS trace files have been purged.\n" >> $v_normal_log_file
          trace_status='S'
        fi
        printf "INFO: purging CRS CDUMP older than ${v_trace_ret} days\n" >> $v_normal_log_file
        age_minutes=`expr ${v_trace_ret} \* 1440`
        CRS_HOME=`${ORACLE_HOME}/bin/adrci exec="show homes"|grep crs`
        ${ORACLE_HOME}/bin/adrci exec="set homepath $CRS_HOME;purge -age $age_minutes -type CDUMP"
        # Error checking
        if [ $v_return_code -ne 0 ]
        then
          printf "Error encountered when purging TRACE!!!\n" >> $v_normal_log_file
          trace_status='F'
        else
          printf "CRS cdump files have been purged.\n" >> $v_normal_log_file
          trace_status='S'
        fi
        printf "INFO: purging CRS ALERT older than ${v_trace_ret} days\n" >> $v_normal_log_file
        age_minutes=`expr ${v_trace_ret} \* 1440`
        CRS_HOME=`${ORACLE_HOME}/bin/adrci exec="show homes"|grep crs`
        ${ORACLE_HOME}/bin/adrci exec="set homepath $CRS_HOME;purge -age $age_minutes -type ALERT"
        # Error checking
        if [ $v_return_code -ne 0 ]
        then
          printf "Error encountered when purging TRACE!!!\n" >> $v_normal_log_file
          trace_status='F'
        else
          printf "CRS alert files have been purged.\n" >> $v_normal_log_file
          trace_status='S'
        fi
        printf "INFO: purging CRS Incidents older than $v_inc_ret days\n" >> $v_normal_log_file
        age_minutes=`expr ${v_inc_ret} \* 1440`
        ${ORACLE_HOME}/bin/adrci exec="set homepath $CRS_HOME;purge -age $age_minutes -type INCIDENT"
        # Error checking
        if [ $v_return_code -ne 0 ]
        then
          printf "Error encountered when purging incidents!!!\n" >> $v_normal_log_file
          in_status='F'
        else
          printf "CRS Incident files have been purged.\n" >> $v_normal_log_file
          in_status='S'
        fi
      fi

      v_return_code=$?
      printf "\n" >> $v_normal_log_file
      printf "=============================================================================\n" >> $v_normal_log_file
      if [ $v_return_code -eq 0 ]
      then
        printf "=       ADRCI purge of $LINE Completed successfully\n" >> $v_normal_log_file
      else
        printf "=       ADRCI purge of $LINE Completed unsuccessfully\n" >> $v_normal_log_file
      fi
      printf "=\n" >> $v_normal_log_file
      printf "=                         `date '+%m/%d/%y %X %A '`\n" >> $v_normal_log_file
      printf "=============================================================================\n" >> $v_normal_log_file
      printf "\n" >> $v_normal_log_file
    fi
  done
printf "\n" >> $v_normal_log_file
printf "=============================================================================\n" >> $v_normal_log_file
 if [ $v_return_code -eq 0 ]
 then
   printf "=                  $v_this_script_name Completed successfully\n" >> $v_normal_log_file
 else
   printf "=                 $v_this_script_name Completed unsuccessfully\n" >> $v_normal_log_file
 fi
 printf "=\n" >> $v_normal_log_file
 printf "=                         `date '+%m/%d/%y %X %A '`\n" >> $v_normal_log_file
 printf "=============================================================================\n" >> $v_normal_log_file

tty -s
if [ $? -eq 1 ]; then
  cat $v_normal_log_file
fi
