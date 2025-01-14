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
SCRDIR="/oradb/app/oracle/local/scripts/monitor/chkidx"





# Change Directory
cd ${SCRDIR}

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
MAILIDS3=`paste -s dba_mail_list_2`

# Define Work Variables
integer SCRPTCNT=0

# Is Script Already Running (Count will be 2 for each run when run via cron)
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "check_for_invisible_indx.ksh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "Script Overlap - Check For Invisible Indexes Already Running on Host `hostname -s`" ${MAILIDS3} < ps_${DBName}.out
 exit 0
fi

# Check For Unusable Indexes
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool invisible_index_count.out
select trim(count(*))
from dba_indexes
where owner  = 'PROD'
and   VISIBILITY = 'INVISIBLE';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo "Error Encountered Checking For invisible Indexes in DataBase ${DBName}" > invisible_indexes.out
   mailx -s "Error Encountered Checking For invisible Indexes in DataBase ${DBName} " ${MAILIDS3} < invisible_indexes.out
   exit 1
EOF
fi

# Get Count Of Invisible Indexes
IDXCNT=`cat invisible_index_count.out`
if [ ${IDXCNT} -gt 0 ] ; then
   echo "${IDXCNT} invisible indexes found in database ${DBName} " > invisible_indexes.out
   mailx -s "invisible Indexes Found In DataBase ${DBName} " ${MAILIDS3} < invisible_indexes.out
fi

# Remove Temp Files 
if [ -f invisible_indexes.out ] ; then
   rm invisible_indexes.out
fi
if [ -f invisible_index_count.out ] ; then
   rm invisible_index_count.out
fi

# Change Permissions
chmod 600 ps_${DBName}.out

