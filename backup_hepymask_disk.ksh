#!/usr/bin/ksh

# Check for Input DataBase and RMAN Script
if [ ${#} -ne 2 ]
then
 echo
 echo "Input DataBase and RMAN Script Not Passed - Script Aborting"
 exit 0
fi

# Set DataBase Name
DBName=$1

# Set Schema Name
CMDFILE=$2

# Change Directory
cd /oradb/app/oracle/local/scripts/backup_to_HE

# Confirm RMAN Command File Exists
if [ ! -f ${CMDFILE} ] ; then
   echo "Input RMAN Command File Not Found"
   exit 1
fi

# Set RMAN Catalog
RCATDB=RCATDEV

# Set Environment
. ~oracle/.bash_profile > /dev/null 2>&1
#PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin
#export PATH
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Set Current DateTime
DATE=`date +%Y-%m-%d_Time_%H-%M-%S`

# Set Log File
LOGFILE=${DBName}_${CMDFILE}_${DATE}.out

# Set Email Distribution
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/backup_to_HE/dba_mail_list`

# Redirect stdout and stderr
exec 1> ${LOGFILE} 2>&1

# Note RMAN Script Start Time
echo "Start Script ${CMDFILE} at "`date`
echo

# Run Input RMAN Command File
rman << EOF
 connect target /
 connect catalog ${DBName}/${RCATPASS}@${RCATDB}
 @${CMDFILE}
EOF

# Send Email
if [ $? -ne 0 ] ; then
   mailx -s "${DBName} Encountered Error Running RMAN Script ${CMDFILE}" ${MAILIDS} < ${LOGFILE}
else
   mailx -s "${DBName} RMAN Script ${CMDFILE} Complete" ${MAILIDS} < ${LOGFILE}
fi

# Note RMAN Script End Time
echo
echo "End Script ${CMDFILE} at "`date`
echo

# Change File Permissions
chmod 600 ${LOGFILE}

