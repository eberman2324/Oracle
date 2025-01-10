#!/bin/ksh


#new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/kill_job"



# Change Directory
cd ${SCRDIR}

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database Name"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName

##########################################################################################################

ps -ef | grep pmon | grep -v grep > pmon1.out
ps -ef| grep ${DBName} pmon1.out |awk '{ print $8 }' | tail -c 10 > instname1.out
DBName=`cat instname1.out`

# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1
##########################################################################################################


# Set DayTime
MMDDYYYY=`date +"%m%d%Y"`



# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/cust_mail_list_1`

# Check and kill Long running sessions
sqlplus > /dev/null <<EOF
/ as sysdba
@kill_lock_job.sql ${MMDDYYYY}
EOF

# If Error
if [ $? -ne 0 ] ; then
   mailx -s "Error Encountered Killing Lock sessions" ${MAILIDS} < KILL_LOCK_SESSIONS_${MMDDYYYY}.out
else
   echo "Killing Lock sessions"
   mailx -s "Killing Lock sessions completed" ${MAILIDS} < KILL_LOCK_SESSIONS_${MMDDYYYY}.out
fi

# remove old output files
#/usr/bin/find ${SCRDIR} -name \*.out -mtime +3 -exec rm -f {} \;

# Change Permissions
#chmod 600 kill_long_running_sessions.sql KILL_LONG_RUNNING_SESSIONS_${MMDDYYYY}.out


