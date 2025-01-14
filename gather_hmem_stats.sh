#!/bin/ksh


# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/stats"




# Change Directory
cd ${SCRDIR}/logs

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database Name"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName

# Set To Day Of The Week
DOW=`date +"%a"`

##########################################################################################################
ps -ef | grep pmon | grep -v grep > pmon_s7.out
ps -ef| grep ${DBName} pmon_s7.out |awk '{ print $8 }' | tail -c 10 > instname_s7.out
DBName=`cat instname_s7.out`



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

##########################################################################################################

# Set Email Distribution
#MAILIDS=schloendornt1@aetna.com
MAILIDS=`paste -s ${SCRDIR}/cust_mail_list`

# Gather Stats
sqlplus > /dev/null <<EOF
/ as sysdba
@${SCRDIR}/gather_hmem_stats.sql ${DOW}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered Gathering Stats on HMEM Tables"
   mailx -s "Error Encountered Gathering Stats on HMEM Tables - ${DBName}" ${MAILIDS} < gather_hmem_stats_${DOW}.out
else
   echo "Gathering Stats completed on HMEM Tables"
   mailx -s "Gathering Stats completed on HMEM Tables - ${DBName}" ${MAILIDS} < gather_hmem_stats_${DOW}.out
fi

# Change Permissions
chmod 600 gather_hmem_stats_${DOW}.out

