#!/usr/bin/ksh

## Enter the number of days to look back from current date
## If hours, enter in format x/24 where x is the no. of hrs
## Example with number of days : grant_permissions_v2.ksh HEDWDEV3 7
## Example with number of hours : grant_permissions_v2.ksh HEDWDEV3 7/12



# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts





# Change To Script Directory
#cd ${SCRDIR}



#clear

#echo  "Enter DataBase Name"
#read DBName

#if [ "$DBName" == "" ] ; then
#   echo "Must Enter DataBase Name"
#   exit 1
#else
#   typeset -u DBName
#fi

#echo
#echo  "Enter the number of days to look back from current date"
#echo  "If hours, enter in format x/24 where x is the no. of hrs"
#read NUMDAYS



# Confirm Input Parameters
if [ ${#} -ne 2 ] ; then
   echo "Must Enter Input Database Name and Number Of Days"
   exit 1
fi


export NUMDAYS=$2
export DBName=$1



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1

# Change to output directory
cd ${SCRDIR}/logs



# Declare Work Variables
MTIME=+187
DT="`date +%Y%m%d_%H%M%S`"
integer SQLERROR=0
integer cnt=0
integer cnt2=0

# See If Any New Objects For This Time Frame
cnt=`sqlplus -s <<EOF
/ as sysdba
set pagesize 0 head off feed off
select count(*)
from   dba_objects
where  owner in ('AE_CUSTOM','PROD_DW')
and    object_type in ('TABLE','VIEW','MATERIALIZED VIEW')
and    object_name not like 'BIN$%'
and    created > sysdate - ${NUMDAYS};
EOF`

# Check If Custom Views Revised
cnt2=`sqlplus -s <<EOF
/ as sysdba
set pagesize 0 head off feed off
select count(*)
from   dba_objects
where  owner = 'PROD_DW'
and    object_type = 'VIEW'
and    object_name not like 'BIN$%'
and    to_date(timestamp, 'YYYY-MM-DD:HH24:MI:SS') > sysdate - ${NUMDAYS}
and    object_name in ('ACCOUNT_HISTORY_FACT','ALL_MEMBER_HISTORY_FACT','AUTH_FACT');
--and    object_name in ('ACCOUNT_HISTORY_FACT','ALL_MEMBER_HISTORY_FACT','AUTH_FACT','MEMBER_HISTORY_FACT');
EOF`

# If No New Objects and No Custom View Revisions
if [ $cnt -eq 0 ] ; then
 if [ $cnt2 -eq 0 ] ; then
    echo
    echo "No New Objects Found For This Time Frame"
    echo
    exit 0
 fi
fi

# If No New Objects but Custom View Revisions
if [ $cnt -eq 0 ] ; then
 if [ $cnt2 -gt 0 ] ; then
    echo
    echo "No New Objects Found For This Time Frame But Custom View(s) Revised"
    echo
    exit 0
 fi
fi

# If New Objects and Custom Views Revised
if [ $cnt -gt 0 ] ; then
 if [ $cnt2 -gt 0 ] ; then
    echo
    echo "Custom View(s) Revisions Found"
    echo
 fi
fi

# Generate Grant Statements
sqlplus -s /nolog << EOF > /dev/null
 whenever sqlerror exit failure
 whenever oserror exit failure
 spool create_grants.sql
 connect / as sysdba
 @${SCRDIR}/ext_create_grants.sql ${NUMDAYS} ${DT}
EOF

# Snag SQLPlus Return Code
SQLERROR=$?

# If Error Encountered
if [ $SQLERROR -ne 0 ] ; then
  echo
  echo "Error Running ext_create_grants.sql"
  exit 1
fi

# Determine If Permissions Are Being Granted
let cnt=0
cnt=`egrep -c "grant select on " create_grants.sql`

# If Permissions Are Being Granted
if [ $cnt -gt 0 ] ; then
   sqlplus /nolog << EOF > /dev/null
   whenever sqlerror exit failure
   whenever oserror exit failure
   spool create_grants.out
   connect / as sysdba
   @create_grants.sql
EOF
   #Snag SQLPlus Return Code
   SQLERROR=$?

   #If Error Encountered
   if [ $SQLERROR -ne 0 ] ; then
      echo
      echo "Error Running create_grants.sql"
      exit 1
   else
      echo
      echo "Grant Statement(s) Applied"
   fi
else
   echo "No Permissions To Grant"
fi

# Change File Permissions
chmod 600 *.sql *.out

# Remove old output files
find ./ -name "*.out" -mtime $MTIME -exec rm -f \{\} \;

