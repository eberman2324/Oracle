#!/bin/ksh

# Check for Input DataBase
if [ ${#} -ne 1 ]
then
 echo
 echo "Input DataBase Not Passed - Script Aborting"
 exit 1
fi

# Set DataBase Name
DBName=$1

# Change Directory
cd ${HOME}/tls/upg19c

# Define Work Variable
integer RC=0

# Set Email Distribution
MAILID=bermane@aetna.com

# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export PATH
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > oraenv_upg19c.out 2>&1

# Change Directory
cd $ORACLE_HOME/rdbms/admin

# Set DataBase Upgrade Version
export UPGVER="19.9.0"

# Upgrade Input DataBase to 19c
$ORACLE_HOME/bin/dbupgrade -d /orahome/u01/app/oracle/product/${UPGVER}/db_1/rdbms/admin -l $ORACLE_BASE/local/logs

#Snag Return Code
RC=$?

#If Error Encountered
if [ $RC -eq 0 ] ; then
  mailx -s "${DBName} upgrade to 19c complete" ${MAILID} < /orahome/u01/app/oracle/local/logs/upg_summary.log  
else
  mailx -s "Error Upgrading ${DBName} to 19c" ${MAILID} < /orahome/u01/app/oracle/local/logs/upg_summary.log  
fi

