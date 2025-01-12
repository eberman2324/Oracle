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

# Set RMAN Catalog For TPAM Lookup (oraenv)
export RCATDB=RCATDEV

# Set Oracle Environment
export PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > /dev/null 2>&1

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Define Log File
TMPLOG=`basename ${RS}`
LOGOUT=`echo ${TMPLOG}|awk -F'.' '{print $1}'`.log

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Confirm Valid Database For This Server
case ${ORACLE_SID} in
     "HEDWDEV")
     ;;
     *)
     echo
     echo "${ORACLE_SID} not a recognized database for this script - script aborting"
     echo
     exit 1
     ;;
esac

# Run Input RMAN Command File
rman << EOF
 connect target /
 connect catalog ${ORACLE_SID}/${RCATPASS}@${RCATDB}
 @${RS}
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   echo "Error Encountered Running Backup For DataBase ${DBName}"
fi

# Change Permissions
chmod 600 ${LOGOUT}

