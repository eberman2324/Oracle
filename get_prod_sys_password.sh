#!/bin/ksh

clear

echo "Enter TPAM Checkout Reason"
read REASON

# Confirm Reason Entered
if [ -z "${REASON}" ]; then
   echo
   echo "Must Enter TPAM Checkout Reason"
   exit 1
fi

# Set To Current Directory
CURDIR=/home/oracle/tls/refresh/HEPYQA3

# Change Directory
cd ${CURDIR}

# Set Oracle Environment
ORACLE_HOME=`cat /etc/oratab | grep "^HEPYQA3:" | cut -d: -f2`
PATH=${ORACLE_HOME}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/quest/bin:./
export ORAENV_ASK=NO
export ORACLE_SID=HEPYQA3
. oraenv

# Set TPAM Account Name
TPAMACCT="xhepydbm21p_HEPYPRD_sys"

# Get SYS Password
SYSPASS=`ssh -i /home/oracle/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com retrieve --AccountName ${TPAMACCT} --SystemName NMA_Oracle --ReasonText ${REASON} |cut -f2`

# Check For TPAM Errors
if [ $? -ne 0 ] ; then
   echo "Error Checking out SYS Password from TPAM"
   exit 1
fi

# Set Database Connection String
DBCON="sys/${SYSPASS}"

echo $DBCON

