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
cd ${SCRDIR}

# Define Work Variable
integer SCRPTCNT=0

# Set Email Distribution
#MAILIDS=schloendornt1@aetna.com,luddym@aetna.com,bermane@aetna.com
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Check To See If Script Is Already Running (Count will be 2 when run via cron)
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "load_hang_analyze.ksh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 #mailx -s "Load Hang Analyze Script Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}.out
 exit 0
fi


##########################################################################################################
ps -ef | grep pmon | grep -v grep > pmon_ha.out
ps -ef| grep ${DBName} pmon_ha.out |awk '{ print $8 }' | tail -c 10 > instname_ha.out
DBName=`cat instname_ha.out`



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

##########################################################################################################
# Set Current Time
DATE=`date +%Y:%m:%d:Time:%H:%M:%S`

# Set Script Output File
OUTFILE=load_hang_analyze_${DATE}.out

# Redirect standard output and standard error to log file
exec 1> ${OUTFILE} 2>&1

echo "Start Hang Analyze Script at `date` "
echo

# Send Email
mailx -s "Start Hang Analyze Script on `hostname -s`" ${MAILIDS} < ${OUTFILE}

sqlplus -s '/ as sysdba' << EOF
 whenever sqlerror exit
 oradebug setmypid
 oradebug unlimit

 declare
 waitfor VARCHAR2(100) := 'library cache lock';

 poll_secs NUMBER := 10;
 wait_usecs NUMBER := 10*10000; ---- micro seconds. it is 100 ms

 junk NUMBER;

 begin
 loop
 begin
 select null into junk
 from v\$session
 where state = 'WAITING'
 and event = waitfor
 and wait_time_micro >= wait_usecs
 and rownum = 1;

 exit;
 exception
 when no_data_found then null;
 end;

 dbms_lock.sleep(poll_secs);

 end loop;
 end;
/
oradebug tracefile_name;
oradebug hanganalyze 4;
oradebug hanganalyze 4;
oradebug hanganalyze 4;

prompt
prompt Running nonracdiag
@nonracdiag.sql

-- This session should be left open as it keeps running every 10 seconds to monitor the specific waits.
 
EOF

echo
echo "Hang Analyze Script Complete at `date` "
echo

# Send Email
mailx -s "End Hang Analyze Script on `hostname -s`" ${MAILIDS} < ${OUTFILE}

# Change Permissions
chmod 600 *.out

