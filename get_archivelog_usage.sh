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


# Define Work Variables
integer PCTUSED=0
integer SCRPTCNT=0

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Is Script Already Running
ps -ef > ps_${DBName}.out
SCRPTCNT=`grep -i "get_archivelog_usage.sh" ps_${DBName}.out |grep -i ${DBName} |grep -v grep |wc -l`
if [ ${SCRPTCNT} -gt 2 ]; then
 mailx -s "Script Overlap - Archive Log Usage Script Already Running on Host ${SERVER} " ${MAILIDS} < ps_${DBName}.out
 exit 0
fi

# Get Percent Used
PCTUSED=`sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off
SELECT max(ROUND((1- (b.free_mb / b.total_mb))*100)) pct_used
FROM v\\$asm_diskgroup a RIGHT OUTER JOIN v\\$asm_disk b USING (group_number)
where b.header_status = 'MEMBER'
and a.name = 'ARCH';
EOF`

if [ ${PCTUSED} -gt 70 ] ; then
 echo "Archivelog Space For DataBase Server ${SERVER} Greater Than ${PCTUSED} Percent Used - Check DDBoost" > arch_usage.lst
 mailx -s "Check Archivelog Space" ${MAILIDS} < arch_usage.lst
 #echo "Check Archivelog Space - ${SERVER} " | sendmail -r schloendornt1@aetna.com -v 2152625546@vtext.com
fi

