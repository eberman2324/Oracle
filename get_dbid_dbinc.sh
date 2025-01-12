#!/usr/bin/ksh

# Obtain DBID and Incarnation at time of backup

# Change Directory
cd $HOME/tls/rman

clear

echo "Enter DataBase Name"
read DBName

# Confirm DataBase Name Entered
if [ -z "${DBName}" ]; then
   echo
   echo "Must Enter DataBase Name"
   exit 1
fi

# Upper Case DataBase Name
typeset -u DBName

echo

echo "Enter Backup Start Time (MM/DD/YYYY HH:MI:SS PM)"
read BKP_START

# Confirm Backup Start Date Entered
if [ -z "${BKP_START}" ]; then
   echo
   echo "Must Enter Backup Start Date"
   exit 1
fi

# Set RMAN Catalog
export RCATDB=RCATDEV

# Set Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Get DataBase ID and Incarnation
sqlplus -s <<EOF > /dev/null
${DBName}/${RCATPASS}@${RCATDB}
set echo off pagesize 0 head off feed off trimspool on term off
spool dbinfo.out
select trim(dbid)||' '||trim(dbinc_key)
from   rc_database_incarnation
where resetlogs_time =
(select max(resetlogs_time)
 from  rc_database_incarnation
 where resetlogs_time < to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
 and   current_incarnation = 'YES');
EOF

DBID=`cat dbinfo.out|awk '{ print $1 }'`
DBINC=`cat dbinfo.out|awk '{ print $2 }'`

echo
echo "Database ID          - " ${DBID}
echo "Database Incarnation - " ${DBINC}
echo

# Remove Spool File
rm dbinfo.out

