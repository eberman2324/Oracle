#!/bin/sh

# Change Directory
cd /home/oracle/tls/rman/logs

# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Get Input DataBase Name
DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`

# Confirm Valid DataBase To Be Restored
case ${DBName} in
     "HEDWSTS")
     ;;
     *)
     echo "${DBName} Not A Valid DataBase For This Script - Script Aborting"
     exit 1
     ;;      
esac

# Set Current DateTime
DATE=`date +%Y:%m:%d:Time:%H:%M:%S`

# Set Script OutPut File
LOGOUT=restore_${DBName}_${DATE}.out

# Set Email Distribution
MAILIDS=bermane@aetna.com

# Set RMAN Catalog
export RCATDB=RCATDEV

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Confirm Heart Beat Script Commented in Cron Before Restore
HBCNT=`crontab -l |egrep -v "^#|confirm" |grep heartbeat|grep ${DBName}|wc -l`
if [ ${HBCNT} -ne 0 ] ; then
   echo "Heart Beat Script Active In Cron For DataBase ${DBName} - Script Aborting"
   exit 1
fi

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Confirm RMAN Restore Script Exists
if [ ! -f ${HOME}/tls/rman/restore_${DBName}.rman ] ; then
   echo "Script ${HOME}/tls/rman/restore_${DBName}.rman not found - Script Aborting"
   exit 1 
fi

echo "Starting Restore of DataBase ${DBName} at - "`date` 
echo

# Restore DataBase
rman << EOF
 connect target /
 connect catalog ${DBName}/${RCATPASS}@${RCATDB}
 @${HOME}/tls/rman/restore_${DBName}.rman
EOF

# Set RMAN Return Code
RC=$?

echo
echo "End Restore of DataBase ${DBName} at - "`date` 

# Send Email
if [ ${RC} -eq 0 ]; then
  mailx -s "Restore of DataBase ${DBName} Complete" ${MAILIDS} < ${LOGOUT}
else
  echo
  echo "Error Running Restore of DataBase ${DBName} "
  echo
  mailx -s "Restore of DataBase ${DBName} - Error Encountered " ${MAILIDS} < ${LOGOUT}
fi

# Change File Permissions
chmod 600 *.out

