#!/bin/ksh

# Get Input DataBase Name
if [ "$1" ]
then
     DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`
else echo "USAGE=${0} <dbname> -  missing database name"
     exit 1
fi

#new standard
# Set To Current Directory
CURDIR=/oradb/app/oracle/local/scripts/space




# Change Directory
cd ${CURDIR}

# Set Current Month/Year
DATE=`date |awk '{ print $2 $6 }'`

# Set Script OutPut File
FN=top_segments_report_${DATE}.out

# Set Email Distribution
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
 @top_segments.sql '${OUTDIR}/${FN}'
EOF

# Set DataBase Return Code
SQLRC=$?

# Check DataBase Return Code
if [ ${SQLRC} -ne 0 ]; then
  echo >> ${OUTDIR}/${OUTFILE}
  echo "Error Running Top Segments Report on Host `hostname -s`" >> ${OUTDIR}/${FN}
  echo >> ${OUTDIR}/${FN}
  mailx -s "Top Segments Report - Error Encountered For ${DBName}" ${MAILIDS} < ${OUTDIR}/${FN}
fi

# Change File Permissions
chmod 600 ${OUTDIR}/${FN}

# Zip OutPut Files Older Than Five Weeks
find ${OUTDIR}/*.out -type f -mtime +35 -exec gzip -f {} \;

