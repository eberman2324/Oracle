#!/bin/sh

# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts





# Change To Script Directory
cd ${SCRDIR}


# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Set To Input Database Name
DBName=$1
typeset -u DBName



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1


# Remove From Previous Run
if [ -f Lock_DW_users.out ] ; then
   rm Lock_DW_users.out
fi


# execute lock
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
spool Lock_DW_users.out
EXECUTE aedba.LOCKUSER;
spool off
EOF



# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Locking Users in Database ${DBName}"
   echo
   exit 1
fi

# If File Not Found
#if [ ! -f Lock_DW_users.out ] ; then
#   echo
#   echo "Error Encountered Locking Users in Database ${DBName}"
#   echo
#   exit 1
#fi

# Change Permissions
chmod 600 Lock_DW_users.out

