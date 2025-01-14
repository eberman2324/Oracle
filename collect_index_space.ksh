#!/bin/ksh

# FileName     : collect_index_space.ksh
# Purpose      : Save index Size Information
# Run Frequency: Weekly


#new standard
# Set To Script Directory
SCRDIR=/oradb/app/oracle/local/scripts/space


# Change Directory
cd ${SCRDIR}


# Check for Input DataBase
if [ ${#} -ne 1 ]
then
 echo
 echo "Input DataBase Not Passed - Script Aborting"
 exit 1
fi

# Set DataBase Name
DBName=$1


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




# Set Script Name
SN=`basename $0`

# Set Host Name
HOSTN=`hostname -s`

# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/dba_mail_list`

# Declare Work Variables
integer RC=0
integer SQLERROR=0

# Declare Work Files
_out=collect_index_space.out
_tmp=connect.out

# Remove Files From Previous Run
rm -f $_out $_tmp



# Verify DataBase Is Up And Accessible
sqlplus -s /nolog << EOF > ${_tmp} 2>&1
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
EOF

# Snag SQLPlus Return Code
SQLERROR=$?

# If Error Connecting - Notify And Exit
if [ $SQLERROR != 0 ] ; then
  echo "Error Connecting To ${DBName} on ${HOSTN}" > ${_tmp}
  echo "Script ${SN} " >> ${_tmp}
  mailx -s "Connect Error - Script ${SN}" ${MAILIDS} < ${_tmp}
  exit 1
fi

# If DataBase Down - Notify and Exit
RC=`grep -c "Connected to an idle instance" ${_tmp}`
if [ $RC -eq 1 ] ; then
  echo "Connected To An Ide Instance - ${DBName} On ${HOSTN}" > ${_tmp}
  echo "Script ${SN} " >> ${_tmp}
  mailx -s "Connected To An Idle Instance - Script ${SN}" ${MAILIDS} < ${_tmp}
  exit 1
fi

# Collect Index Space Information
sqlplus -s /nolog << EOF > ${_tmp} 2>&1
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set line 140 trimspool on
 spool $_out
 select name,
  to_char(sysdate, 'MON-DD-YYYY HH:MI:SS AM') as "Start Time" from v\$database;
 set heading off trimspool on

 --Delete rows older than 2 years excluding first row of each month
 prompt Deleting Data Older Than 2 Years Excluding First Row of Each Month
 delete aedba.index_growth_history
 where timestamp < trunc(sysdate, 'DD') -732
 and to_number(to_char(timestamp, 'DD')) > 7;

 commit;

 --Delete rows older than 3 years
 prompt Deleting Data Older Than 3 Years
 delete aedba.index_growth_history
 where timestamp < trunc(sysdate, 'DD') -1096;

 commit;

 --Collect current index information
 prompt Inserting Current Into Information
 insert into aedba.index_growth_history
 (index_owner,index_name,tablespace_name,extents,bytes,num_rows)
  select ds.owner,
        segment_name,
        ds.tablespace_name,
        extents,
        bytes,
        -1
 from   dba_segments ds,
        dba_indexes dt
 where  segment_type = 'INDEX'
 and    segment_name = index_name
 and    ds.owner = dt.owner
 and    ds.owner = 'PROD'
 /

 commit;

 --Update Num_Rows Column
-- prompt Updating Num_Rows Column
-- @upd_num_rows_1.sql

-- set heading on

-- select to_char(sysdate, 'MON-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

 spool off

EOF


# Change File Permissions
chmod 600 $_out $_tmp

# Check For Errors
egrep "ORA-|Error updating table" $_out > /dev/null
if [[ $? -eq 0 ]]; then
   mailx -s "${SN} Error - ${HOSTN}" ${MAILIDS} < $_out
   exit 1
fi

egrep "ORA-" $_tmp > /dev/null
if [[ $? -eq 0 ]]; then
   mailx -s "${SN} Error - ${HOSTN}" ${MAILIDS} < $_tmp
   exit 1
fi

# Gather Stats
sqlplus -s /nolog << EOF > ${_tmp} 2>&1
 whenever sqlerror exit failure
 connect / as sysdba
 exec dbms_stats.gather_table_stats(ownname=>'AEDBA', tabname=>'INDEX_GROWTH_HISTORY', degree=>2, no_invalidate=>false, cascade=>true);
EOF

# Snag SQLPlus Return Code
SQLERROR=$?

# If Error Gathering Stats - Notify and Exit
if [ $SQLERROR != 0 ] ; then
  echo "Error Gathering Stats on Table INDEX_GROWTH_HISTORY in ${DBName} on ${HOSTN}" > ${_tmp}
  echo >> ${_tmp}
  echo "Script ${SN} " >> ${_tmp}
  mailx -s "Gather Stats Error - Script ${SN}" ${MAILIDS} < ${_tmp}
  exit 1
fi

# Send Script Completion Email
mailx -s "${SN} complete - ${HOSTN}" ${MAILIDS} < $_out

