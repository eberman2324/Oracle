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
SCRDIR=/oradb/app/oracle/local/scripts/backup



# Change Directory
cd ${SCRDIR}/logs

################################################################################################

ps -ef | grep pmon | grep -v grep > pmon_cb2.out
ps -ef| grep ${DBName} pmon_cb2.out |awk '{ print $8 }' | tail -c 10 > instname_cb2.out
DBName=`cat instname_cb2.out`


# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

###################################################################################################

# Set Log File Name
LOGFILE=check_for_running_backup_${DBName}.log

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Note Script Start Time
echo "Starting Script $0 at "`date` > ${LOGFILE}
echo >> ${LOGFILE}

echo "Checking For Running Backups for DataBase ${DBName} " >> ${LOGFILE}
echo >> ${LOGFILE}

# Check For Backup Running Longer Than 2 Days 
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool backup_run_count.out
select trim(count(*))
 from v\$rman_backup_subjob_details
 where status like '%RUNNING%'
 and start_time < sysdate-2;
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo >> ${LOGFILE}
   echo "Error Checking For Running Backups For DataBase ${DBName}" >> ${LOGFILE}
   echo >> ${LOGFILE}
   mailx -s "DataBase Running Backup Check - Error Encountered For ${DBName}" ${MAILIDS} < ${LOGFILE}
else
   ERRCNT=`cat backup_run_count.out`
   if [ ${ERRCNT} -gt 0 ] ; then
      echo >> ${LOGFILE}
      echo "DataBase ${DBName} Backup Running For More Than 2 Days" >> ${LOGFILE}
      echo >> ${LOGFILE}
      mailx -s "DataBase Running Backup Check - ${DBName}" ${MAILIDS} < ${LOGFILE}
      echo >> ${LOGFILE}
   fi
fi

# Note Script End Time
echo >> ${LOGFILE}
echo "Ending Script $0 at "`date` >> ${LOGFILE}
echo >> ${LOGFILE}

# Change File Permissions
chmod 600 *.log *.out

