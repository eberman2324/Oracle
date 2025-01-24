#!/bin/ksh
################################################################################
## Script: hang_monitor.ksh
## Purpose: Back up database
##    
## Usage: To see usage type 
##             hang_monitor.sh -?
################################################################################

process_commandline()
{
   # Loop through command line options
   while getopts :terc:o:i:d: OPTION $*
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
      exit_error "Config param TARGET_SID not set"
   fi 
   export ORACLE_SID=$TARGET_SID


}

print_usage()
{
   echo
   echo "Usage:"
   echo "   $SCRIPT -i <sid of target instance>"
   echo "     -t Indicates that logging should be to the terminal"
   echo "        rather than the normal log file"
   echo "     -i <target instance>"
   echo "        SID of the instance being backed up"
}

run_check()
{
   sqlplus -S /nolog <<-EOF
	set heading off
	set linesize 1024
	set trimspool on
	set echo off
	set termout off
	set feedback off
	set verify off
	set pagesize 0
	whenever sqlerror exit failure
	connect / as sysdba
	spool $PARAMETER_TEMP
	select  'PARAMETERS' as ROWFLAG,
                (select translate(decode(state, 'ACTIVE', 'OK', 'IDLE', 'OK', 'APPLYING', 'OK', state), ' ', '_') as standby_state
                       from V\$LOGSTDBY_STATE
                ) as standby_state,
       	        (select (sysdate-APPLIED_TIME)*3600*24 from V\$LOGSTDBY_PROGRESS
                ) as seconds_latency
	  from dual 
	/
	spool off
	EOF
   if [ $? -ne 0 ] 
   then
      log_message "Error running check sql"
      return 2
   fi

   STANDBY_STATE=`awk '/PARAMETERS/ {print $2}' $PARAMETER_TEMP`
   SECONDS_LATENCY=`awk '/PARAMETERS/ {print $3}' $PARAMETER_TEMP`

   log_message "standby_state=$STANDBY_STATE"
   log_message "seconds_latency=$SECONDS_LATENCY"

   SENT_PAGE_COUNT=`check_for_sent_page`

   if [ "$STANDBY_STATE" != "OK" -o "$SECONDS_LATENCY" -gt 1800 ]
   then

      if [ "$SENT_PAGE_COUNT" -eq 0 ]
      then
         # Start the counting
         log_message "Updating $SENT_PAGE file to 1"
         echo "1" > $SENT_PAGE
         export SENT_PAGE_COUNT=1
      fi

      log_message "Issue detected with standby"
      send_notification "$DIST1" "standby_state=$STANDBY_STATE : seconds_latency=$SECONDS_LATENCY" 

   else
      echo "0" > $SENT_PAGE
   fi    
   return 0
}

### Note:
### SENT_PAGE = 0 means that all's clear.  Nothing going on.
### SENT_PAGE >= 1 means that something is going on and we're counting.
check_for_sent_page()
{
   typeset -i COUNT
   if [ -f $SENT_PAGE ]
   then
      COUNT=`cat $SENT_PAGE`
      log_message "Found SENT_PAGE file with value $COUNT"
      if [ "$COUNT" -lt 5 -a "$COUNT" -gt 0 ]
      then
         let COUNT=${COUNT}+1
         echo $COUNT > $SENT_PAGE 
         log_message "Increasing count to $COUNT"
      else
         log_message "COUNT=$COUNT.  Clearing sent page file and setting COUNT to 1"
         COUNT=1
         echo "1" > $SENT_PAGE
      fi
   else
      echo "0" > $SENT_PAGE
      COUNT=0
   fi
   echo $COUNT
}
                                                                              

##
## Returns the "second of the year" to use as a timer so
## might be wrong if the job runs accross midnight on 12/31
get_seconds()
{
   date +%j:%H:%M:%S | awk -F":" '{s=$1*86400+$2*3600+$3*60+$4;print s}'
}

check_for_errors()
{
	egrep -c 'ORA-|OCI-|PLS-|SQL-|SP2-|EXP-' $1
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

send_notification()
{
   typeset DISTRIBUTION=$1
   log_message "Sending notification"
   mail -s "$ORACLE_SID: Logical Standby Error" "$DISTRIBUTION" <<-EOF
	$2
	EOF
}

exit_error()
{
   log_message "$1"
   send_notification "$DIST1" "$1"
   cleanup
   exit 1
}

exit_success()
{
   log_message "$1" >> $LOGFILE
   cleanup
   exit 0
}

cleanup()
{
   rm -f $TMP_LOG
   rm -f $PARAMETER_TEMP
}

############## Main ########################
export PATH=/usr/bin:/usr/sbin:/usr/local/bin:$PATH
SCRIPT=`basename $0`
WORKHOME=/home/oracle

DATE=`date +%Y%m%d`

ORAENV=/usr/local/bin/oraenv
ORAENV_ASK=NO

SQLPLUS="sqlplus"
AWK=awk
TEMPDIR=/tmp
LOG_DIR=$WORKHOME/logs
LOGFILE=$LOG_DIR/$SCRIPT.$DATE.log
STDOUT=$LOG_DIR/$SCRIPT.$DATE.stdout
DIST1="swaffordm@aetna.com"
TMP_LOG=$TEMPDIR/tmp_log$$.log
PARAMETER_TEMP=$TEMPDIR/$SCRIPT.parameters.$$
SENT_PAGE=$TEMPDIR/$SCRIPT.sent_page

### Start sending any misc stuff to the stdout log
exec 1>$STDOUT
exec 2>&1

# Initialize
process_commandline $*

log_message "$ORACLE_SID"

# Source oracle environment
. oraenv

run_check
if [ $? -ne 0 ]
then
   JOB_ERROR_FLAG=1
   exit_error "Processing error encountered in hang_check.  See log for details." 
fi

exit_success "Done"
