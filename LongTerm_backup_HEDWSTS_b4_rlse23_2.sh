#!/bin/ksh

# Set To Script Directory
CURDIR="/home/oracle/tls/rman"

# Change Directory
cd ${CURDIR}

# Confirm Input Parameters
if [ ${#} -ne 2 ] ; then
   echo "Must Enter Input Database Name and RMAN Script Name"
   exit 1
fi

# Set To Input Database Name
DBName=$1
typeset -u DBName

# Set RMAN Script Name
RS=$2

# Confirm RMAN Script Exists
if [ ! -f ${RS} ]; then
   echo
   echo "RMAN Script ${RS} Not Found - Script Aborting"
   exit 1
fi

# Set RMAN Catalog
export RCATDB=RCATDEV

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1


# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Backup Existing Archive Logs Prior to Below Backup Being Kept
${SCRIPTS}/backup_archive_logs.sh ${DBName}

# Define Log File
LOGOUT=backup_HEDWSTS_B4_RLSE23_2.log

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Confirm Valid Database For This Server
case ${ORACLE_SID} in
     "HEDWSTS")
     ;;
     *)
     echo
     echo "${ORACLE_SID} not a recognized database on this server - script aborting"
     echo
     exit 1
     ;;
esac

# Check For Existing Restore Point
RPCNT=`sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off
select count(*)
from   v\\$restore_point
where  upper(name) = 'B4_RLSE23_2';
EOF`

# If Restore Point Exists
if [ ${RPCNT} -ne 0 ] ; then
   echo "Restore Point B4_RLSE23_2 Exists - Script Aborting"
   exit 1
fi

echo "Starting Backup of DataBase ${DBName} at - "`date` 
echo

# Run Input RMAN Command File
rman << EOF
 connect target /
 connect catalog ${ORACLE_SID}/${RCATPASS}@${RCATDB}
 @${RS}
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   echo "Error Encountered Running Backup For DataBase ${DBName}"
   exit 1
fi

echo
echo "End Backup of DataBase ${DBName} at - "`date` 
echo

# Generate Save Backup Commands
${CURDIR}/ext_save_backup.sh ${DBName}

# Change Permissions
chmod 600 ${LOGOUT} *.rman

