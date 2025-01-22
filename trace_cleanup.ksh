#!/bin/ksh
################################################################################
## Script: trace_cleanup.ksh
## Purpose: Script to clean up alert and listener logs for all instances and
##          listeners on a box.
##    
## Usage: log_cleanup.ksh
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
         \:) print_usage
             exit_error "Missing argument for option: $OPTARG"
             ;;
         ?)  print_usage
             exit_error "Unknown option: $OPTION"
             ;;
        esac
   done

}

print_usage()
{
   echo
   echo "Usage:"
   echo "   $SCRIPT [-t]"
   echo "     -t Indicates that logging should be to the terminal"
   echo "        rather than the normal log file"
}

#
# Clean up the text version of the alert log (not the xml)
#
cleanup_instance_alert_log()
{
   typeset iname=$1
   typeset -i task_error=0

   # Set the oracle environment
   oenv $iname
   
   # Get the directory for the alert log and the alert log name
   typeset logdir=`show_parameter background_dump_dest`
   typeset logfile=alert_${iname}.log
   typeset newname="$logfile".$DATETIME

   # Make sure the alert log exists and return if it doesn't 
   if [ ! -f $logdir/$logfile ]
   then
      log_message "Log not found: $logdir/$logfile"
      return 1
   else 
      # Rename the log
      mv $logdir/$logfile $logdir/$newname
      if [ $? -ne 0 ]
      then
         log_message "Unable to move $logdir/$logfile to $logdir/$newname"
         ((task_error+=1))
      fi

      # Zip up the old one (the one we renamed)
      gzip $logdir/$newname
      if [ $? -ne 0 ]
      then
         log_message "Unable to zip $logdir/$newname"
         ((task_error+=1))
      fi

      # Find and purge copies older than the RETENTION days
      find $logdir/. ! -name '.' -prune -type f -name $logfile.\* -mtime +$RETENTION -exec rm {} \;
      if [ $? -ne 0 ]
      then
         log_message "Unable to remove old log files from $logdir"
         ((task_error+=1))
      fi
   fi
   return $task_error
}

#
# Clean up the text version of the listener logs
#
cleanup_listener_trace_log()
{
	set +x
   typeset lname=$1

   # Get the listener log directory and file name from lsnrctl.
   # Assume that we're not using ADR to start with
   typeset logfile=`basename \`show_listener_parameter $lname log_file\``
   typeset logdir=`show_listener_parameter $lname log_dir`
   typeset fileext=`basename $logfile | $AWK -F'.' '{print $2}'`
   typeset -i task_error=0

   ## Using AWR?
   if [ "$fileext" = "xml" ]
   then
      # If so, change the log directory from alert to trace and the name
      # to be .log rather than .xml
      logdir=`dirname $logdir`"/trace"
      logfile=${lname}.log
   fi
   
   # Move the text version of the log to one with DATETIME appended
   typeset newname="$logfile".$DATETIME

   # Make sure the log exists first 
   if [ ! -f $logdir/$logfile ]
   then
      # Exit here, don't continue
      log_message "Log not found: $logdir/$logfile"
      return 1
   else 
      # Rename the current log file
      mv $logdir/$logfile $logdir/$newname
      if [ $? -ne 0 ]
      then
         log_message "Unable to move $logdir/$logfile to $logdir/$newname"
         ((task_error+=1))
      fi
      
      # Zip up the log we just renamed
      gzip $logdir/$newname
      if [ $? -ne 0 ]
      then
         log_message "Unable to zip $logdir/$logfile"
         ((task_error+=1))
      fi

      # Find and remove copies older than RETENTION days
      find $logdir/. ! -name '.' -prune -type f -name $logfile.\* -mtime +$RETENTION -exec rm {} \;
      if [ $? -ne 0 ]
      then
         log_message "Unable to remove old log files from $logdir"
         ((task_error+=1))
      fi
   fi
	set +x
   return $task_error
}

#
# Use the adrci utility to clean up any trace files under ADR that aren't
# being cleaned up automatically.  By using adrci, they will abide by the
# SHORTP_POLICY and LONGP_POLICY defined for the ADR home.
#
adr_cleanup()
{
   typeset adr_base=$1
   typeset adr_home=$2
   
   adrci exec = "set base $adr_base; set home $adr_home ; purge" | tee $TMP_LOG #> $TMP_LOG
   if [ `check_for_errors $TMP_LOG` -ne 0 ]
   then
      log_message "Errors found while purging $adr_base:$adr_home"
      return 1
   fi
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
   egrep -c 'ORA-|OCI-|PLS-|SQL-|SP2-|DIA-' $1
}


#
# Log a timestamped message to the job log for this job.
#
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

#
# Log a message to the message log and exit with a non-zero return code
# 
exit_error()
{
   log_message "$1"
   #$SCRIPTS/notify.ksh swaffordm@aetna.com "$1"
   exit 1
}

#
# Log a message to the message log and exit with zero (success)
# 
exit_success()
{
   log_message "$1" >> $LOGFILE
   exit 0
}

# 
# Clean up any temp files created
#
cleanup()
{
#   rm -f $TMP_LOG
cat $TMP_LOG
}

############## Main ########################
export PATH=/usr/bin:/usr/sbin:/usr/local/bin:$PATH
AWK=awk
SCRIPT=`basename $0`
DATE=`date +%Y%m%d`
DATETIME=`date +%Y%m%d%H%M%S`
WORKHOME=/workability/home/oracle
SCRIPTS=/orahome/wkab01/aetna/scripts

# Load common functions
. $SCRIPTS/common_functions.ksh

TEMPDIR=/tmp
LOG_DIR=$WORKHOME/logs
LOGFILE=$LOG_DIR/$SCRIPT.$DATE.log
TMP_LOG=$TEMPDIR/$$.tmp_log

typeset -i JOB_ERRORS=0

## Default retention for logs in days
RETENTION=90

# Initialize
process_commandline $*

#  
# Do ADR cleanup (traces and stuff) using the purge
# command on each adr home
#
for b in `list_adr_bases`
do
   for h in `list_adr_homes $b`
   do
      log_message "Processing: ${b}${h}"
      adr_cleanup $b $h
      if [ $? -gt 0 ]
      then
         ((JOB_ERRORS+=1))
      fi
   done
done

## Rename and purge instance alert log in trace for running instances
for i in `list_running -i`
do
   log_message "Processing Instance: $i"
   cleanup_instance_alert_log $i
   if [ $? -gt 0 ]
   then
      ((JOB_ERRORS+=1))
   fi
done

## Rename and purge listener trace log for running listeners
for lsn in `list_running -l`
do
   log_message "Processing Listener: $lsn"
   cleanup_listener_trace_log $lsn
   if [ $? -gt 0 ]
   then
      ((JOB_ERRORS+=1))
   fi
done

if [ $JOB_ERRORS -gt 0 ]
then
   exit_error "$JOB_ERRORS Errors encountered while processing job $JOB"
fi
 
log_message "Done"
cleanup

