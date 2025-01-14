#!/bin/ksh

DBName="+ASM1"


# new standard
# Set To Current Directory
CURDIR=/oradb/app/oracle/local/scripts/space


# Change Directory
cd ${CURDIR}

# Set Current Month/Year
DATE=`date |awk '{ print $2 $6 }'`

# Set Script OutPut File
FN=asm_usage_report_${DATE}.out

# Set Email Distribution
MAILIDS=`paste -s ${CURDIR}/dba_mail_list`





# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1





# Set Script OutPut Directory
OUTDIR=${CURDIR}/ASM

# Create Output Directory If Not Exists
if [ ! -d ${OUTDIR} ] ; then
   mkdir -p ${OUTDIR}
   chmod 700 ${OUTDIR}
fi

# Get ASM Space Usage
echo >> ${OUTDIR}/${FN}
echo "ASM Space Usage at "`date` >> ${OUTDIR}/${FN}
echo >> ${OUTDIR}/${FN}
asmcmd lsdg >> ${OUTDIR}/${FN}
echo >> ${OUTDIR}/${FN}

# Append To End of Report
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 connect / as sysdba
 set pagesize 0 trimspool on linesize 160 feed off
 spool '${OUTDIR}/${FN}' APPEND
 select substr(rpad(dummy,135,'-'),2) from dual;
 select substr(rpad(dummy,135,'-'),2) from dual;
 spool off
EOF

# Set DataBase Return Code
SQLRC=$?

# Check DataBase Return Code
if [ ${SQLRC} -ne 0 ]; then
  echo >> ${OUTDIR}/${OUTFILE}
  echo "Error Getting ASM Space Usage on Host `hostname -s`" >> ${OUTDIR}/${FN}
  echo >> ${OUTDIR}/${FN}
  mailx -s "ASM Usage Report - Error Encountered " ${MAILIDS} < ${OUTDIR}/${FN}
fi

# Change File Permissions
chmod 600 ${OUTDIR}/${FN}

# Zip OutPut Files Older Than Five Weeks
find ${OUTDIR}/*.out -type f -mtime +35 -exec gzip -f {} \;

