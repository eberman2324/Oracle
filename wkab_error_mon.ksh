#!/bin/ksh93
################################################################################
## Script: wkab_error_mon.ksh
## Purpose: Back up database
##    
## Usage: To see usage type 
##             wkab_error_mon.sh -?
################################################################################

process_commandline()
{
   # Loop through command line options
   while getopts ti:w:h:e OPTION $*
   do
      case $OPTION in
         t)  LOG_TO_TERMINAL="Y"
             echo "Logging set to terminal"
             ;;
         i)  TARGET_SID=$OPTARG
             ;;
         w)  scan_window=$OPTARG
             ;;
         h)  log_message "Option h not used"
             ;;
         e)  log_message "Option e not used"
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

   if [ -z "$scan_window" ]
   then
      export scan_window=10
   fi 

   log_message "Window minutes: $scan_window"

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
   echo "     -w <scan window in minutes>"
   echo "        number of minutes to look back in the log for errors"
   echo "     -h <Threshold>"
   echo "        Number of errors in window that will trigger an alert."
   echo "     -e <Error Fragment>"
   echo "        Text to scan for.  Note -e must be the last argument."
}

run_check()
{
   sqlplus -S /nolog <<-EOF > ${PARAMETER_TEMP}
	set heading on
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
	select /*+ index(s_error_log T_ERROR_LOG_IDX02) */
               'PARAMETERS' as ROWFLAG,
                 count(*) as errors_last_n_minutes,
		nvl(sum(case when err_desc like '%${err1_fragment}%' then 1 else 0 end),0) as ERR1,
		nvl(sum(case when err_desc like '%${err2_fragment}%' then 1 else 0 end),0) as ERR2
	  from s_error_log
	 where create_date > sysdate - $scan_window/1440
	/
	spool off
	EOF
   if [ $? -ne 0 ] 
   then
      log_message "Error running check sql"
      return 2
   fi

   ERRORS_IN_WINDOW=`awk '/PARAMETERS/ {print $2}' $PARAMETER_TEMP`
   ERR1=`awk '/PARAMETERS/ {print $3}' $PARAMETER_TEMP`
   ERR2=`awk '/PARAMETERS/ {print $4}' $PARAMETER_TEMP`

   log_message "Total Errors in last $scan_window minutes = $ERRORS_IN_WINDOW"
   log_message "Count of ${err1_fragment} = $ERR1"
   log_message "Count of ${err2_fragment} = $ERR2"

   if [ "$ERR1" -ge "$err1_threshold" ]
   then
      send_notification $ERR1 "$err1_fragment"
   fi
   if [ "$ERR2" -ge "$err2_threshold" ]
   then
      send_notification $ERR2 "$err2_fragment"
   fi    

   return 0
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
   typeset ERRCNT=$1
   typeset MSG=$2

   log_message "Sending notification"
   echo "Oracle Instance: $TARGET_SID" > $NOTIF_MESSAGE
   echo "Workability Application Error: $MSG" >> $NOTIF_MESSAGE
   echo "\nErrors in last $scan_window minutes: $ERRCNT" >> $NOTIF_MESSAGE

   mail -s "Alert: WKAB Application Errors found by wkab_error_mon" $DISTRIBUTION < $NOTIF_MESSAGE

   rm $NOTIF_MESSAGE
}

job_failure_notify()
{
   log_message "Sending job failure notification"
   echo "Oracle Instance: $TARGET_SID" > $NOTIF_MESSAGE
   echo "See error log: $LOGFILE"  >> $NOTIF_MESSAGE

   mail -s "$ORACLE_SID: errors executing wkab_error_mon" $FAILURE_DISTRIBUTION < $NOTIF_MESSAGE

   rm $NOTIF_MESSAGE
}

exit_error()
{
	echo "$1"
   log_message "$1"
   job_failure_notify "$1"
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
WORKHOME=/workability/home/oracle

DATE=`date +%Y%m%d`

ORAENV=/usr/local/bin/oraenv
ORAENV_ASK=NO

SQLPLUS="sqlplus"
AWK=awk
TEMPDIR=/tmp
LOG_DIR=$WORKHOME/logs
LOGFILE=$LOG_DIR/$SCRIPT.$DATE.log
STDOUT=$LOG_DIR/$SCRIPT.$DATE.stdout
TMP_LOG=$TEMPDIR/tmp_log$$.log
#DISTRIBUTION="swaffordm@aetna.com"
DISTRIBUTION="ESMEmailAlerts@aetna.com swaffordm@aetna.com bermane@aetna.com GervaseS@aetna.com"
FAILURE_DISTRIBUTION="swaffordm@aetna.com"
PARAMETER_TEMP=$TEMPDIR/$SCRIPT.parameters.$$
NOTIF_MESSAGE=$TEMPDIR/$SCRIPT.notif.$$
export err1_fragment="Unable to connect to SQL Server session database"
export err2_fragment="The requested service%could not be activated."
export err1_threshold=50
export err2_threshold=1

### Start sending any misc stuff to the stdout log
exec 1>$STDOUT
exec 2>&1

# Initialize
process_commandline $@


log_message "$ORACLE_SID"

# Source oracle environment
. $ORAENV

run_check
if [ $? -ne 0 ]
then
   exit_error "Processing error encountered in $SCRIPT.  See $LOGFILE for details." 
fi

exit_success "Done"
