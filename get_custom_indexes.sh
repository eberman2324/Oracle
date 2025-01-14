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


# Set To Input Script Directory
SCRDIR=/oradb/app/oracle/local/scripts/monitor/chkidx



# Change Directory
cd ${SCRDIR}/logs



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



# Check For Custom Indexes Created Over The Last Week
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool index_count.out
select trim(count(*))
from dba_objects
where object_type = 'INDEX'
and   object_name like '%AEDBA%'
and   created > trunc(sysdate)-7;
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo "Error Encountered Checking For Custom Indexes" > ${OUTFILE}
   mailx -s "${DBName} Check For Custom Index Error" ${MAILIDS} < ${OUTFILE}
   exit 1
fi

# Get Index Count
IDXCNT=`cat index_count.out`

# If No Custom Index Created In The Last Seven Days
if [ ${IDXCNT} -eq 0 ] ; then
   exit 0 
fi

# Define Script OutPut File
OUTFILE=${DBName}_custom_indexes_`date +%Y%m%d_%H%M%S`.out

# Redirect standard output and standard error to log file
exec 1> ${OUTFILE} 2>&1

echo "Custom Indexes Created in ${DBName} over the last 7 days"
echo

sqlplus -s <<EOF
 / as sysdba
whenever sqlerror exit failure;
col owner for a20
col table_name for a30
col index_name for a30
col created for a30
set pagesize 100 linesize 200
prompt
select i.owner,
       table_name,
       index_name,
       created
from  dba_indexes i,
      dba_objects o
where i.owner = o.owner
and   i.index_name = o.object_name
and   o.object_type = 'INDEX'
and   created > trunc(sysdate)-7
and   index_name like '%AEDBA%'
order by 4;
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Extracting Custom Indexes" > ${OUTFILE}
   mailx -s "${DBName} Custom Index Extract Error" ${MAILIDS} < ${OUTFILE}
fi

# Send Email
mailx -s "${DBName} Custom Index Created In The Last Week" ${MAILIDS} < ${OUTFILE}

# Change File Permissions
chmod 600 *.out

