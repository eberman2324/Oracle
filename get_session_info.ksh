#!/bin/ksh

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database Name"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName


# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/monitor/orasupp"


# Change Directory
cd ${SCRDIR}/logs

# Define Work Variables
integer SCRPTCNT=0

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`



##########################################################################################################
ps -ef | grep pmon | grep -v grep > pmon.out
ps -ef| grep ${DBName} pmon.out |awk '{ print $8 }' | tail -c 10 > instname.out
DBName=`cat instname.out`



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

##########################################################################################################



# Check To See If Script Is Already Running - 2 Processes Forked When Run via Cron
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "get_session_info.ksh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "Get Session Info Script Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}.out
 exit 0
fi

# Set Current Date
DATE=`date +%Y-%m-%d`

# Set Script OutPut File
FN=get_session_info_${DATE}.out


# Get Session Info
sqlplus -s /nolog << EOF
 connect / as sysdba
 whenever sqlerror exit failure;
 @${SCRDIR}/get_session_info.sql ${FN}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo "See File ${SCRDIR}/logs/${FN}" > err.txt
   mailx -s "Error Encountered Running Script Get Session Info on Host `hostname -s`" ${MAILIDS} < err.txt
   rm err.txt
   exit 1
fi

# Change Permissions
chmod 600 ${FN}

# Zip OutPut Files Older Than 1 Day
find ${SCRDIR}/logs/get_session_info*.out -type f -mtime +0 -exec gzip -f {} \;

