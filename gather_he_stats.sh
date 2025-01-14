#!/bin/ksh


# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/stats"





# Change Directory
cd ${SCRDIR}/logs

# Confirm Input Database Passed In
if [ ${#} -ne 1 ] ; then
   echo "Must Pass Input Database"
   exit 1
fi

# Set Input DataBase Name
DBName=$1

# Upper Case DataBase Name
typeset -u DBName

# Set To Day Of The Week
DOW=`date +"%a"`

##########################################################################################################
ps -ef | grep pmon | grep -v grep > pmon_s6.out
ps -ef| grep ${DBName} pmon_s6.out |awk '{ print $8 }' | tail -c 10 > instname_s6.out
DBName=`cat instname_s6.out`



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



# Define Work Variables
integer SCRPTCNT=0

# Is Script Already Running
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "gather_he_stats.sh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "H-E Gather Stats Script Overlap - Script Already Running on Host `hostname -s`" ${MAILIDS} < ps_${DBName}.out
 echo "Stats Job Already Running - Script Aborting" > gather_he_stats_${DOW}.out
 exit 0
fi

# Gather Stats
sqlplus -s <<EOF
/ as sysdba
@${SCRDIR}/gather_he_stats.sql ${DOW}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Encountered Gathering Stats on Health Edge Supplied Tables"
   mailx -s "Error Encountered Gathering Stats on Health Edge Tables - ${DBName}" ${MAILIDS} < gather_he_stats_${DOW}.out
else
   echo "Gathering Stats completed on Health Edge Supplied Tables"
   mailx -s "Gathering Stats completed on Health Edge Tables - ${DBName}" ${MAILIDS} < gather_he_stats_${DOW}.out
fi



# Change Permissions
chmod 600 gather_he_stats_${DOW}.out ps_${DBName}.out

