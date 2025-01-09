#!/bin/ksh
#**************************************************************************
#  Script name:  monitor_inactive_cons.ksh
#  Description:  Monitor inactive connections         
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

integer session_count
export session_count

orasid=$ORACLE_SID
dt=`date +%m%d%y`
tm=`date +%H%M%S`

logfile="${LOGDIR}inactive.${orasid}.${dt}.${tm}.log"

exec >>$logfile
exec 2>&1

get_block_count() {
sqlplus -s "/ as sysdba" <<-%
-- system/no734s
@${SQLDIR}db_queries_active.sql 
%
}

get_session_count() {
sqlplus -s "/ as sysdba" <<-%|read session_count
@${SQLDIR}sessioncount.sql 
%
}


get_block_count
get_session_count

if [[ ${session_count} -gt 300 ]]
then
#mail -s "Hourly Connections from WKABPROD" "weicheljm@aetna.com swaffordm@aetna.com khersonskyr2@aetna.com bermane@aetna.com" <$logfile
mail -s "Hourly Connections from WKABPROD" "bermanE@aetna.com" <$logfile
fi
find ${LOGDIR} -name "*inactive*.log" -mtime +5 -exec rm -f {}  \;
