#!/bin/ksh
#**************************************************************************
#  Script name:  monitor_blocking_locks.ksh
#  Description:  Alert if there are any blocking locks
#**************************************************************************
#set -x


# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Set To Input Database Name
DBName=$1
typeset -u DBName


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


#new standard
export SQLDIR="/oradb/app/oracle/local/scripts/monitor/blocking/"
export LOGDIR="/oradb/app/oracle/local/scripts/monitor/blocking/logs/"
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/monitor/blocking/cust_mail_list`





integer block_count
export block_count

orasid=$ORACLE_SID
dt=`date +%m%d%y`
tm=`date +%H%M%S`

logfile="${LOGDIR}block.${orasid}.${dt}.log"

exec >>$logfile
exec 2>&1

get_block_count() {
sqlplus -s "/ as sysdba" <<-%|read block_count
@${SQLDIR}block.sql 
%
}

get_block_count

if [[ ${block_count} -eq 0 ]]
then
 echo "`date +'%x %X -'` NO BLOCKING LOCKS CURRENTLY HELD IN DATABASE $orasid"
else
 echo "`date +'%x %X -'` BLOCKING LOCKS FOUND, DOUBLE CHECKING $orasid"
  sleep 300
  get_block_count
  if [[ ${block_count} -gt 0 ]]
  then
    echo "`date +'%x %X -'` WHO IS THE CULPRIT"
    sqlplus -s "/ as sysdba" <<-%
    @${SQLDIR}check_blockers.sql 
    --exit
%
    #echo "${orasid} might have blocking locks. Please look into it." | mail bermanE@aetna.com
    mailx -s "${orasid} might have blocking locks. Please look into it." ${MAILIDS} < ${logfile}
 
  fi
fi


# remove old output files
/usr/bin/find ${SQLDIR}/logs -name \*.log -mtime +3 -exec rm -f {} \;
