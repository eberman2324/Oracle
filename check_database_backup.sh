#!/bin/ksh

# Confirm Input Database
if [ ${#} -eq 0 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Set To Input Database
DBName=$1

# Upper Case Database Name
typeset -u DBName


#new standard
# Set Script Directory
SCRDIR=/oradb/app/oracle/local/scripts/rman


# Change Directory
cd ${SCRDIR}/logs

################################################################################################

ps -ef | grep pmon | grep -v grep > pmon_cb1.out
ps -ef| grep ${DBName} pmon_cb1.out |awk '{ print $8 }' | tail -c 10 > instname_cb1.out
DBName=`cat instname_cb1.out`


# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

###################################################################################################

# Set Log File Name
LOGFILE=check_database_backup_${DBName}.log

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Define Work Variables
integer CNT=0
integer ERRCNT=0
integer SQLRC=0

# Note Script Start Time
echo "Starting Script $0 at "`date` > ${LOGFILE}
echo >> ${LOGFILE}

echo "Checking Backup for DataBase ${DBName} " >> ${LOGFILE}
echo >> ${LOGFILE}

# Confirm Backup Has Run Recently
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool backup_count.out
select trim(count(*))
 from v\$backup_set_details
 where completion_time > sysdate-1
 and incremental_level in (0,1);
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error Checking For Recently Run Backup For DataBase ${DBName}" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - Error Encountered For ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

CNT=`cat backup_count.out`
if [ ${CNT} -eq 0 ] ; then
   echo >> ${LOGFILE}
   echo "Level 0 or 1 Backup of DataBase ${DBName} Not Run Recently" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

# Check To See If Backup Failure Already Reported
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool backup_count.out
select trim(count(*))
from  v\$rman_backup_job_details
where input_type = 'DB INCR'
and   status     = 'FAILED'
and   start_time > sysdate-1;
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error encountered checking for incremental backup failures in the last 24 hours" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - Error Encountered For ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

CNT=`cat backup_count.out`
if [ ${CNT} -gt 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error - Incremental backup failure encountered in the last 24 hours" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

# Check Backup For Errors
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool backup_err_count.out
select trim(count(*))
 from v\$rman_backup_subjob_details sd, 
      v\$backup_set_details bsd
 where sd.session_key = bsd.session_key 
  and sd.session_recid = bsd.session_recid 
  and sd.session_stamp = bsd.session_stamp 
  and sd.end_time > sysdate-1
  and bsd.incremental_level in (0,1)
  and sd.status is not null
  and sd.status not in ('COMPLETED','RUNNING');
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered Checking For Backup Errors
if [ $SQLRC -ne 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error Checking Backup Activity For DataBase ${DBName}" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - Error Encountered For ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

ERRCNT=`cat backup_err_count.out`
if [ ${ERRCNT} -eq 0 ] ; then
   echo >> ${LOGFILE}
   echo "No Error Encountered With Backup of DataBase ${DBName}" >> ${LOGFILE}
   echo >> ${LOGFILE}
   exit 0
fi

# Confirm All Data Files Backed Up
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool backup_count.out
select trim(count(*))
from  v\$datafile df
where not exists
     (select 1
      from   v\$backup_files bf
      where file_type = 'DATAFILE'
      and   bs_completion_time  > sysdate-1
      and   file# = df_file#);
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error encountered confirming all data files were backed up in the last 24 hours" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - Error Encountered For ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

CNT=`cat backup_count.out`
if [ ${CNT} -gt 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error - Not all data files backed up in the last 24 hours" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Backup Check - ${DBName}" ${MAILIDS} < ${LOGFILE}
   exit 1
fi

# Note Script End Time
echo >> ${LOGFILE}
echo "Ending Script $0 at "`date` >> ${LOGFILE}
echo >> ${LOGFILE}

# Change File Permissions
chmod 600 *.log *.out

