#!/usr/bin/ksh

# This script updates the date/time column with
# the current time.  This table can be referenced
# after an RMAN restore/duplication to confirm the
# restore point of the database.
#
# Note: This script may be called by other scripts
#       and is also scheduled in cron.
#       Script returns 0 if an error is encountered
#       to allow the other scripts to continue.

# Check for Input DataBase and Schema
if [ ${#} -ne 2 ]
then
 echo
 echo "Input DataBase and Schema Not Passed - Script Aborting"
 exit 0
fi

# Set DataBase Name
DBName=$1

# Set Schema Name
SCHema=$2

# Change Directory
cd /oradb/app/oracle/local/scripts/monitor/rman/temp


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

# Set Email Distribution
#MAILIDS=bermane@cvshealth.com
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/monitor/rman/dba_mail_list`

# Define Work Variables
integer ROWCNT=0
integer TBLCNT=0
integer SCRPTCNT=0

# Is Script Already Running
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "heartbeat.ksh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l` 
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "HeartBeat Script Overlap - Heartbeat Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}.out
 exit 0
fi

# Determine If Table Exists
TBLCNT=`sqlplus -s <<EOF
/ as sysdba
set pagesize 0 head off feed off
select count(*)
from   dba_tables
where  owner = '${SCHema}'
and    table_name = 'RMAN_HEARTBEAT';
EOF`

# If Table Does Not Exist
if [ ${TBLCNT} -eq 0 ] ; then
   mailx -s "HeartBeat Script Error - Heartbeat Table Not Found in ${DBName} For Schema ${SCHema}" ${MAILIDS} < /dev/null
   exit 0
fi

# Determine If Record Exists For This DB
ROWCNT=`sqlplus -s <<EOF
/ as sysdba
set pagesize 0 head off feed off
select count(*)
from   ${SCHema}.RMAN_HEARTBEAT
where  DBNAME = '${DBName}';
EOF`

# Update HeartBeat TimeStamp
if [ ${ROWCNT} -gt 0 ]; then
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set trimspool on feed off linesize 120
 spool heartbeat_${DBName}_${SCHema}.out
 select name as DBNAME,
        to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time"
 from   v\$database;
 prompt
 select to_char(timestmp, 'MM-DD-YYYY HH:MI:SS AM') as "Previous TimeStamp"
 from   ${SCHema}.RMAN_HEARTBEAT
 where  DBNAME = '${DBName}';
 prompt
 update ${SCHema}.RMAN_HEARTBEAT
 set    timestmp=sysdate
 where  DBNAME = '${DBName}';
 commit;
 prompt
 select to_char(timestmp, 'MM-DD-YYYY HH:MI:SS AM') as "Current TimeStamp"
 from   ${SCHema}.RMAN_HEARTBEAT
 where  DBNAME = '${DBName}';
 prompt
 select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;
 spool off
EOF
else
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set trimspool on feed off linesize 120
 spool heartbeat_${DBName}_${SCHema}.out
 select name as DBNAME,
        to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time"
 from   v\$database;
 prompt
 insert into ${SCHema}.RMAN_HEARTBEAT values('$DBName',sysdate);
 commit;
 prompt
 select to_char(timestmp, 'MM-DD-YYYY HH:MI:SS AM') as "Current TimeStamp"
 from   ${SCHema}.RMAN_HEARTBEAT
 where  DBNAME = '${DBName}';
 prompt
 select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;
 spool off
EOF
fi

# If Error Encountered
if [ $? -ne 0 ] ; then
   mailx -s "${DBName} HeartBeat For Schema ${SCHema} Script Error" ${MAILIDS} < heartbeat_${DBName}_${SCHema}.out
   exit 0
fi

