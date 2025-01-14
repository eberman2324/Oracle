#!/bin/ksh

#new standard
# Set To Script Directory
SCRDIR=/oradb/app/oracle/local/scripts/space


# Change Directory
cd ${SCRDIR}/logs

# Check for Input DataBase
if [ ${#} -ne 1 ]
then
 echo
 echo "Input DataBase Not Passed - Script Aborting"
 exit 1
fi

# Set DataBase Name
DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`

##########################################################################################################
ps -ef| grep pmon > pmon.out
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

# Define Work Variables
integer PCTUSED=0
integer SCRPTCNT=0

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Is Script Already Running
ps -ef > ps_${DBName}_fra.out
SCRPTCNT=`grep -i "get_fra_usage.sh" ps_${DBName}_fra.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "Script Overlap - FRA Usage Script Already Running on Host ${SERVER} " ${MAILIDS} < ps_${DBName}_fra.out
 exit 0
fi

# Get Percent Used
PCTUSED=`sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
@${SCRDIR}/get_fra_usage.sql
EOF`

if [ ${PCTUSED} -gt 70 ] ; then
   echo "FRA Space Used By DataBase ${DBName} Greater Than ${PCTUSED} Percent" > fra_usage.lst
   mailx -s "Check FRA Space" ${MAILIDS} < fra_usage.lst
   #echo "Check FRA Space - ${DBName} " | sendmail -r schloendornt1@aetna.com -v 2152625546@vtext.com
fi

