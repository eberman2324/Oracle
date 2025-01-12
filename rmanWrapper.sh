# how to run examples
#20 18 * * 0 /home/oracle/tls/rman/rmanWrapper.sh HEPYPRD rmanCommand.rman > /dev/null 2>/dev/null
#nohup rmanWrapper.sh HEPYPRD rmanCommand.rman

#!/bin/sh

# Set To Script Directory
SCRDIR="/home/oracle/tls/rman"

# Change Directory
cd ${SCRDIR}/logs

# Confirm Input Parameters
if [ ${#} -ne 2 ] ; then
   echo "Must Enter Input Database Name and RMAN Command File"
   exit 1
fi

# Set Input DataBase Name
DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`

# Set Input Command File Name
CMDFILE=$2

# Confirm RMAN Command File Exists
if [ ! -f ${SCRDIR}/${CMDFILE} ] ; then
   echo "Input RMAN Command File Not Found"
   exit 1
fi

# Set Current DateTime
DATE=`date +%Y:%m:%d:Time:%H:%M:%S`

# Set Script OutPut File
LOGOUT=rmanWrapper_${DBName}.out

# Set Email Distribution
MAILIDS=bermane@aetna.com

# Set RMAN Catalog
export RCATDB=RCATPROD

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`
echo ${RCATPASS}

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

echo "Starting rman command in DataBase ${DBName} at - "`date` 
echo

# Run Input RMAN Command File
rman << EOF
 connect target /
 connect catalog ${DBName}/${RCATPASS}@${RCATDB}
 @${SCRDIR}/${CMDFILE}
EOF

# Set RMAN Return Code
RC=$?

echo
echo "End rman command in DataBase ${DBName} at - "`date` 

# If Error Encountered
if [ ${RC} -ne 0 ]; then
  mailx -s "Rman command in DataBase ${DBName} - Error Encountered " ${MAILIDS} < ${LOGOUT}
  exit 1
fi

# Inspect Log
#EXPCNT=`egrep -i "expired|rman-|validation failed for" ${LOGOUT} |wc -l`

# If Attention Required
#if [ ${EXPCNT} -gt 0 ]; then
  mailx -s "Rman command in DataBase ${DBName} Complete - Review Output" ${MAILIDS} < ${LOGOUT}
#fi

# Change File Permissions
chmod 600 *.out

