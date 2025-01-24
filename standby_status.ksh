#!/bin/ksh
################################################################################
## Script: standby_status.ksh
## Purpose: Back up database
##    
## Usage: To see usage type 
##             standby_status.sh -?
################################################################################


run_check()
{
   sqlplus -S /nolog <<-EOF
	set linesize 1024
	set echo off
	set verify off
	set pagesize 1024
	whenever sqlerror exit failure
	connect / as sysdba
	@$WORKHOME/sql/logical_standby_status.sql
	/
	spool off
	EOF
   if [ $? -ne 0 ] 
   then
      echo "Error running check sql"
      return 2
   fi

   return 0
}

##
## Returns the "second of the year" to use as a timer so
## might be wrong if the job runs accross midnight on 12/31
get_seconds()
{
   date +%j:%H:%M:%S | awk -F":" '{s=$1*86400+$2*3600+$3*60+$4;print s}'
}

exit_error()
{
   cleanup
   exit 1
}

exit_success()
{
   cleanup
   exit 0
}

cleanup()
{
   rm -f $TMP_LOG 2> /dev/null
}

############## Main ########################
export PATH=/usr/bin:/usr/sbin:/usr/local/bin:$PATH
SCRIPT=`basename $0`
WORKHOME=/u37/aetna/scripts/standby

DATE=`date +%Y%m%d`

ORAENV=/usr/local/bin/oraenv
ORAENV_ASK=NO

TEMPDIR=/tmp
TMP_LOG=$TEMPDIR/tmp_log$$.log

# Source oracle environment
. oraenv

echo "################################### Standby Status Information for $ORACLE_SID ################################"
run_check
if [ $? -ne 0 ]
then
   JOB_ERROR_FLAG=1
   exit_error "Processing error encountered in hang_check.  See log for details." 
fi

exit_success "Done"
