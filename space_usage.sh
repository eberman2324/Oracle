#!/bin/sh

# Get Input DataBase Name
if [ "$1" ]
then
     DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`
else echo "USAGE=${0} <dbname> -  missing database name"
     exit 1
fi

# new standard
# Change Directory
cd /oradb/app/oracle/local/scripts/space
# Set To Current Directory
CURDIR=/oradb/app/oracle/local/scripts/space





# Set Current Month/Year
DATE=`date |awk '{ print $2 $6 }'`

# Set Script OutPut File
OUTFILE=tablespace_report_${DATE}.out

MAILIDS=`paste -s ${CURDIR}/dba_mail_list`


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

# Set Script OutPut Directory
OUTDIR=${CURDIR}/${DBName}

# Create Output Directory If Not Exists
if [ ! -d ${OUTDIR} ] ; then
   mkdir -p ${OUTDIR}
   chmod 700 ${OUTDIR}
fi

# Create Space Report
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 connect / as sysdba
 @space_usage.sql '${OUTDIR}/${OUTFILE}'
EOF

# Set DataBase Return Code
SQLRC=$?

# Check DataBase Return Code
if [ ${SQLRC} -ne 0 ]; then
  echo >> ${OUTDIR}/${OUTFILE}
  echo "Error Running TableSpace Report on Host `hostname -s`" >> ${OUTDIR}/${OUTFILE}
  echo >> ${OUTDIR}/${OUTFILE}
  mailx -s "Space Usage Report - Error Encountered For ${DBName}" ${MAILIDS} < ${OUTDIR}/${OUTFILE}
fi

# Change File Permissions
chmod 600 ${OUTDIR}/${OUTFILE}

# Remove Output Files older than 2 years
find ${OUTDIR} -name tablespace_report_\* -mtime +731 -exec rm -f {} \;



