#!/bin/ksh
################################################################################
## Script: who.ksh
## Purpose: Report on active sessions in the specified instance
##    
## Usage: who.sh [-f CONFIG_FILE ]
##      CONFIG_FILE - The full path the the configuration file that contains the
##                    configuration settings for this script
################################################################################

process_commandline()
{
   # Loop through command line options
   while getopts :ti: OPTION $*
   do
      case $OPTION in
         t)  LOG_TO_TERMINAL="Y"
             echo "Logging set to terminal"
             ;;
         i)  TARGET_SID=$OPTARG
             ;;
         \:) print_usage
             exit_error "Missing argument for option: $OPTARG"
             ;;
         ?)  print_usage
             exit_error "Unknown option: $OPTION"
             ;;
        esac
   done

   # Process variables from command line
   if [ -z "$TARGET_SID" ]
   then
      TARGET_SID=$ORACLE_SID
      if [ -z "$TARGET_SID" ]
      then
         exit_error "Config param TARGET_SID not found in config file and ORACLE_SID not set"
      fi
   fi 
   export ORACLE_SID=$TARGET_SID

}

print_usage()
{
   echo
   echo "Usage:"
   echo "   $SCRIPT -i <sid of target instance> [-t]"
   echo "     -t Indicates that logging should be to the terminal"
   echo "        rather than the normal log file"
}

run_sql()
{
   $SQLPLUS -S -L /nolog <<-EOF >> $TMP_LOG
	whenever sqlerror exit failure
	set pagesize 1024
	set linesize 1024
	set trimspool on
	set tab off
	connect / as sysdba
	select cast(SYS_CONTEXT('USERENV', 'DB_NAME') as varchar2(10)) as Instance,
	       to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') as DATETIME 
	from dual;
select decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID, 
       s.sid, 
       p.spid, 
       substr(decode(s.type, 'USER', s.username, 'BACKGROUND', 'ORA-' ||bg.name, s.username), 1, 15) as username, 
       substr(decode(aa.name, 'UNKNOWN', '--', aa.name ), 1, 15) as command,
       s.status,
       substr(s.osuser, 1, 15) as osuser, 
       substr(s.machine, 1, 30) as machine,
       substr(s.program, 1, 20) as program, 
       substr(s.module, 1, 15) as module,
       substr(s.action, 1, 15) as action,
       s.sql_hash_value,
       sw.event,
		 s.lockwait,
		 s.row_wait_obj#,
		 s.row_wait_row#,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time, 
       s.last_call_et,
       sio.block_gets,
       sio.consistent_gets,
       sio.physical_reads,
       sio.block_changes,
       sio.consistent_changes
from v\$session s,
     v\$process p,
     v\$sess_io sio,
     v\$px_session pxs,
     v\$bgprocess bg,
     audit_actions aa,
     v\$session_wait sw
where s.paddr = p.addr
  and s.sid = sio.sid
  and s.saddr = pxs.saddr (+)
  and s.command = aa.action
  and s.paddr = bg.paddr (+)
  and s.status = 'ACTIVE'
  and s.type <> 'BACKGROUND'
  and s.sid = sw.sid
order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid)
/

	select sid, seconds_in_wait, event , P1, P2, P3
	from v\$session_wait 
	where event not in (select event from perfstat.stats\$idle_event);

	select b.sid, b.username, b.osuser, used_ublk, start_time
	from v\$transaction a, v\$session b
	where a.ses_addr = b.saddr
/
	select * from dba_waiters;

select '--- OLDTRAN ---', 
		 decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID, 
       s.sid, 
       p.spid, 
       substr(decode(s.type, 'USER', s.username, 'BACKGROUND', 'ORA-' ||bg.name, s.username), 1, 15) as username, 
       substr(decode(aa.name, 'UNKNOWN', '--', aa.name ), 1, 15) as command,
       s.status,
       substr(s.osuser, 1, 15) as osuser, 
       substr(s.machine, 1, 30) as machine,
       substr(s.program, 1, 20) as program, 
       substr(s.module, 1, 15) as module,
       substr(s.action, 1, 15) as action,
       s.sql_hash_value,
       s.prev_hash_value,
       sw.event,
       s.lockwait,
       s.row_wait_obj#,
       s.row_wait_row#,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time, 
       s.last_call_et
from v\$session s,
     v\$process p,
     v\$sess_io sio,
     v\$px_session pxs,
     v\$bgprocess bg,
     audit_actions aa,
     v\$session_wait sw,
     v\$transaction t
where s.paddr = p.addr
  and s.sid = sio.sid
  and s.saddr = pxs.saddr (+)
  and s.command = aa.action
  and s.paddr = bg.paddr (+)
  and s.saddr = t.ses_addr 
  and to_date(t.start_time, 'MM/DD/YY HH24:MI:SS') < sysdate - 1/1440
  and s.sid = sw.sid
order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid)
/

EOF
   ERR=$?
   if [ "$ERR" -ne 0 ]
   then
      log_message "Error $ERR encoutered running SQL.  See log for details." 
      cat $TMP_LOG
      return -2
   fi

   check_for_errors $TMP_LOG

   # Successful
   return 0
}

append_to_log()
{
   if [ -f $TMP_LOG ]
   then
      cat $TMP_LOG >> $LOGFILE
   fi
}

check_for_errors()
{
	egrep -c 'ORA-|OCI-|PLS-|SQL-|SP2-' $1
}

log_message()
{
   typeset MESSAGEDATE=`date +"%Y-%m-%d %H:%M:%S :"`
   if [ -z "$LOG_TO_TERMINAL" ]
   then
      print -n "$MESSAGEDATE" >> $LOGFILE
      print "$1" >> $LOGFILE
   else
      print -n "$MESSAGEDATE" 
      print "$1"
   fi
}

exit_error()
{
   log_message "$1"
   exit 1
}

exit_success()
{
   log_message "$1" >> $LOGFILE
   exit 0
}

cleanup()
{
   rm -f $TMP_LOG
}

############## Main ########################
export PATH=/usr/bin:/usr/sbin:/usr/local/bin:$PATH
SCRIPT=`basename $0`
DATE=`date +%Y%m%d`
WORKHOME=/workability/home/oracle/

ORAENV=/usr/local/bin/oraenv
ORAENV_ASK=NO

SQLPLUS="sqlplus"
AWK=awk
TEMPDIR=/tmp
LOG_DIR=$WORKHOME/logs
LOGFILE=$LOG_DIR/$SCRIPT.$DATE.log
TMP_LOG=$TEMPDIR/$$.tmp_log

# Initialize
process_commandline $*

log_message "$ORACLE_SID"

# Source oracle environment
. $ORAENV

log_message "Starting $SCRIPT for $TARGET_SID"

# Run sql
run_sql
if [ $? -ne 0 ]
then
   exit_error "Errors encountered while running sql"
fi

append_to_log
   
log_message "Done"
cleanup

