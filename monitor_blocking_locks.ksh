#!/bin/ksh
#**************************************************************************
#  Script name:  monitor_blocking_locks.ksh
#  Description:  Alert if there are any blocking locks
#  Creation Date: Dev 03
#  Run Frequency: Daily
#  Author: Vish Belagur
#  Revised: Robert Holden
#**************************************************************************
#set -x

export PATH=/usr/local/bin:/usr/bin:/etc:/usr/sbin:/usr/ucb:/usr/bin/X11:/sbin:/usr/lbin:.:
export ORACLE_SID=wkabprod
export ORAENV_ASK=NO
. oraenv
export ORACLE_TERM=vt220

export PRODDIR="/workability/home/oracle/Monitor/"
export SCRDIR="${PRODDIR}/Scripts/"
export SQLDIR="${PRODDIR}/Sql/"
export PARMDIR="${PRODDIR}/Parms/"
export LOGDIR="${PRODDIR}/Logs/"
export PAGEDIR="/orabin/prod/bin/"

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
-- system/no734s
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
  if [[ ${block_count} -eq 0 ]]
  then
   echo "`date +'%x %X -'` NO BLOCKING LOCKS CURRENTLY HELD IN DATABASE $orasid"
  else
#    echo "`date +'%x %X -'` OBJECT LOCKS CURRENTLY HELD IN DATABASE $orasid\n"
#    sqlplus -s <<-%
#    system/wkabprod
#    @$SQLDIR/lock.sql
#%
    echo "\n `date +'%x %X -'` WHO IS THE CULPRIT\n"
    sqlplus -s "/ as sysdba" <<-%
    -- system/wkabprod
    @?/rdbms/admin/utllockt.sql
    exit
%
    echo "${orasid} might have blocking locks. Please look into it." | mail KhersonskyR2@aetna.com krawetzkypj@aetna.com bermanE@aetna.com aetna-oracle@inventa.com swaffordm@aetna.com
  fi
fi
