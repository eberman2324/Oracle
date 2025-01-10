#!/bin/ksh



# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/monitor/rman"



# Change To Script Directory
cd ${SCRDIR}/logs



# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Set To Input Database Name
DBName=$1
typeset -u DBName

################################################################################################

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

###################################################################################################



# Define Log File
LOGOUT=check_for_grp.log

# Define Mail Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Remove From Previous Run
if [ -f grp_count.out ] ; then
   rm grp_count.out
fi

# Define Work Variables
integer SCRPTCNT=0

# Is Script Already Running
ps -ef > ps_${DBName}_grp.out
SCRPTCNT=`grep -i "check_for_grp.ksh" ps_${DBName}_grp.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "GRP Script Overlap - Check For GRP Script Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}_grp.out
 exit 0
fi

# Check For Restore Point
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool grp_count.out
select trim(count(*))
from v\$restore_point
where guarantee_flashback_database = 'YES';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Checking for GRP in Database ${DBName}"
   echo
   mailx -s "Error Encountered Checking For Guarantee Restore Point" ${MAILIDS} < ${LOGOUT}
   exit 1
fi

# If File Not Found
if [ ! -f grp_count.out ] ; then
   echo
   echo "Error Encountered - File Not Created Checking for GRP in Database ${DBName}"
   echo
   mailx -s "Error Encountered Checking For Restore Point" ${MAILIDS} < ${LOGOUT}
   exit 1
fi

CNT=`cat grp_count.out`
if [ ${CNT} -gt 0 ] ; then
   echo
   echo "Guarantee Restore Point(s) Found in Database ${DBName}"
   echo
   mailx -s "Warning - Guarantee Restore Point(s) Found in Database ${DBName}" ${MAILIDS} < ${LOGOUT}
fi

# Change Permissions
chmod 600 ${LOGOUT} grp_count.out ps_${DBName}_grp.out

