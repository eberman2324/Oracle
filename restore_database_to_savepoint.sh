#!/bin/sh

# Note: This script was written in support of rolling back an app change.
#       The script expects the database to be up and accessible.

# Change Directory
cd /home/oracle/tls/rman

# Check For Input DataBase Name and Restore Point
if [ ${#} -ne 2 ]
then
 echo
 echo "Input DataBase Name and Restore Point Not Passed - Script Aborting"
 exit 1
fi

# Get Input DataBase Name
DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`

# Get Input Restore Point
RESTORE_POINT=`echo $2 |tr "[:lower:]" "[:upper:]"`

# Set Current DateTime
DATE=`date +%Y:%m:%d:Time:%H:%M:%S`

# Set Log Directory
LOGDIR=/home/oracle/tls/rman/logs

# Set Script OutPut File
LOGOUT=${LOGDIR}/restore_database_${DBName}_to_savepoint_${RESTORE_POINT}_${DATE}.out

# Set Email Distribution
MAILIDS=schloendornt1@aetna.com

# Set RMAN Catalog
export RCATDB=RCATDEV

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Check For Input Restore Point
RPCNT=`sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off
select count(*)
from   v\\$restore_point
where  upper(name) = '${RESTORE_POINT}';
EOF`

# Confirm Input Restore Point Found
if [ ${RPCNT} -ne 1 ] ; then
   echo "Input Restore Point ${RESTORE_POINT} Not Found - Script Aborting"
   exit 1
fi

# Confirm Heart Beat Script Commented in Cron Before Restore
HBCNT=`crontab -l |grep -v "^#" |grep heartbeat|grep ${DBName}|wc -l`
if [ ${HBCNT} -ne 0 ] ; then
   echo "Heart Beat Script Active In Cron - Script Aborting"
   exit 1
fi

# Mount The DataBase To Be Restored
sqlplus -s << EOF
/ as sysdba
whenever sqlerror exit failure;
startup force mount;
EOF

# Restore DataBase To Input Restore Point
rman << EOF
 connect target /
 connect catalog ${DBName}/${RCATPASS}@${RCATDB}
 run {
 set until restore point "${RESTORE_POINT}";
 restore database;
 recover database;
 }
 alter database disable block change tracking;
 alter database enable block change tracking using file '+DATA_01';
 alter database open resetlogs;
EOF

# Set RMAN Return Code
RC=$?

# Send Email
if [ ${RC} -eq 0 ]; then
  mailx -s "Restore of DataBase ${DBName} to Save Point ${RESTORE_POINT} Complete" ${MAILIDS} < ${LOGOUT}
else
  echo
  echo "Error Running Restore of DataBase ${DBName} to Save Point ${RESTORE_POINT} "
  echo
  mailx -s "Restore of DataBase ${DBName} - Error Encountered " ${MAILIDS} < ${LOGOUT}
fi

# Change File Permissions
chmod 600 ${LOGOUT}

