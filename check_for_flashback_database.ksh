#!/bin/ksh



# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/monitor/rman"




# Change Directory
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
LOGOUT=check_for_fbd.log

# Define Mail Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Remove From Previous Run
if [ -f fbd_count.out ] ; then
   rm fbd_count.out
fi

# Define Work Variables
integer SCRPTCNT=0

# Is Script Already Running
ps -ef > ps_${DBName}_fbd.out
SCRPTCNT=`grep -i "check_for_flashback_database.ksh" ps_${DBName}_fbd.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "FDB Script Overlap - Check For FDB Script Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}_fbd.out
 exit 0
fi

# Check For Flashback Database
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool fbd_count.out
select trim(count(*))
from v\$database
where flashback_on = 'YES';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Checking for Flashback Database in Database ${DBName}"
   echo
   mailx -s "Error Encountered Checking For Flashback Database" ${MAILIDS} < ${LOGOUT}
   exit 1
fi

# If File Not Found
if [ ! -f fbd_count.out ] ; then
   echo
   echo "Error Encountered - File Not Created Checking for Flashback Database in Database ${DBName}"
   echo
   mailx -s "Error Encountered Checking For Flashback Database" ${MAILIDS} < ${LOGOUT}
   exit 1
fi

CNT=`cat fbd_count.out`
if [ ${CNT} -gt 0 ] ; then
   echo
   echo "Flashback Database on in Database ${DBName}"
   echo
   mailx -s "Warning - Flashback Database on in Database ${DBName}" ${MAILIDS} < ${LOGOUT}
fi

# Change Permissions
chmod 600 ${LOGOUT} fbd_count.out ps_${DBName}_fbd.out

