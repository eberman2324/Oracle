#!/bin/ksh

USAGE="Usage:  scan_orafile.ksh arg1 (where arg1 is ORACLE output file name) arg2 (where arg2 is ORACLE_SID)"

#
# ---------------------------------------------------------
#  file:    scan_orafile.ksh
#
#  called by:  scan_oracle.ksh
#
#  author:  Mark Lantsberger   Oracle version
#           Cindy Wiech        major enhancements
#
#  purpose: A Korn Shell script for warning the Database Administrator
#           about potential problems with the Oracle Alert Logs &
#           Trace Files. See scan_oracle
#
#  useage:  This script accepts one argument, a file name.  This file 
#           should be an Oracle alert log or trace file as determined by 
#           the calling script (scan_oracle.ksh).
#           If this is supplied, it will be used in the script to be
#           reformatted and scanned against the WORRIES file and the
#           NO_WORRIES file to detect Oracle errors that the DBA cares 
#           about and wants to be notified of when they happen.
#           If the file is not supplied the script will terminate.
#
#  process: This script formats the input file ($ORAFILE - which should
#           be an Oracle alert log or trace file).
#           The script calls an awk program (scan_log.awk) to do 
#           the reformatting so that a time and date appears on
#           each line in the Oracle output file.
#           The script then looks for occurrences of error 
#           conditions as listed in the WORRIES file and 
#           excludes expressions listed in the NO_WORRIES file.  
#           If an error is found, the DBA's are notified via e-mail.
#
#  notes:
#
#  The reliability of this script for alerting the DBA to potential
#  server problems depends entirely on the contents of the WORRIES and
#  NO_WORRIES files. The WORRIES file should contain regular expressions
#  which will capture suspicious text. The NO_WORRIES file will evolve.
#  Each time this script picks up text that is not of any real concern,
#  carefully construct a regular expression that will filter it out and
#  append it to the NO_WORRIES file.
#
#  As an example, the WORRIES file might contain:
#
#           Error
#           ERROR
#           Msg
#           ORA-00604
#
#  After being alerted to several occurrences of error 1608 and
#  discovering that it is caused by your users hitting ^C to abort the
#  client process, you may want to add one line to the NO_WORRIES file
#  which reads:
#           Error: 1608[^0-9]
#
#  Note that the expression has been designed so that it will filter out
#  the inconsequential 1608 error, but will not filter out similar text
#  that *would* be of concern. 
#
# change history:
# 01/30/2010 TS Revised For 11g
# 04/06/2007 TS  Revised For BroadSpire Environment
# 10/05/2017 EB  Revised For HealthEdge
# 07/09/2024 EB Revised For HealhEdge RACONE


# Check for Input File and DataBase Name
if [ ${#} -ne 2 ]
then
 echo ${USAGE}
 exit 1
fi


SCRIPTS=/oradb/app/oracle/local/scripts/monitor
ORACLE_BASE=/oradb/app/oracle




export ORAENV_ASK=NO
ORAFILE=$1
ORACLE_SID=$2
DB_UNIQUE_NAME=$3




export BDUMP=${ORACLE_BASE}/diag/rdbms/${DB_UNIQUE_NAME}/${ORACLE_SID} | tr "[:upper:]" "[:lower:]"/trace;
ORAFILE_AWK=${SCRIPTS}/scan_log.awk

WORK_FILE=${BDUMP}/orafile.tmp

WORRIES=${SCRIPTS}/worries

NO_WORRIES=${SCRIPTS}/no_worries

FERR_FILE=${BDUMP}/filtered_err

NEW_FERR_FILE=${BDUMP}/new_filtered

#new standard
MAILTO_C=/oradb/app/oracle/local/scripts/mail/dba_mail_list
MAILTO=/oradb/app/oracle/local/scripts/mail/mailto.sh



EMPTY_FILE=$SCRIPTS/empty_file

#    ------------------------------------------------------------
#    Extract the current year, month day and hour for this run of 
#    scan_log (i.e., previous hour of this day).
#    ------------------------------------------------------------

MON=`date +"%h"`
YEAR=`date +"%Y"`
DAY=`date +"%a"`
DAYNUM=`date +"%d"`
TIME=`date +"%T" | cut -c1-2`
MIN=`date +"%T" | cut -c4-5`

#########################################################
# function definitions start here
########################################################

init_process()
{
   #    -------------------------------------------------------------
   #    Check to see whether the input oracle file exists. If not, exit.
   #    -------------------------------------------------------------

   if [ ! -f $ORAFILE ]
   then
      exit
   fi 

   #    -------------------------------------------------------------
   #    Check to see whether temporary file exists. If so, remove it.
   #    -------------------------------------------------------------

   if [ -f $NEW_FERR_FILE ] 
   then
      rm $NEW_FERR_FILE
   fi

   #    -------------------------------------------------------------
   #    Check to see whether the error file exits  If not, create one.
   #    -------------------------------------------------------------

   if [ ! -f $FERR_FILE ] 
   then
      touch $FERR_FILE
   fi

   return 
}

change_day()
{
   if [ $DAYNUM == "01" ]
   then
      DAYNUM="1"
   fi

   if [ $DAYNUM == "02" ]
   then
      DAYNUM="2"
   fi

   if [ $DAYNUM == "03" ]
   then
      DAYNUM="3"
   fi

   if [ $DAYNUM == "04" ]
   then
      DAYNUM="4"
   fi

   if [ $DAYNUM == "05" ]
   then
      DAYNUM="5"
   fi

   if [ $DAYNUM == "06" ]
   then
      DAYNUM="6"
   fi

   if [ $DAYNUM == "07" ]
   then
      DAYNUM="7"
   fi

   if [ $DAYNUM == "08" ]
   then
      DAYNUM="8"
   fi

   if [ $DAYNUM == "09" ]
   then
      DAYNUM="9"
   fi

   return 
}

pre_process_alert_log()
{

   if [ -f $WORK_FILE ]
   then
      rm $WORK_FILE
   fi

   #nawk -f $ORAFILE_AWK $ORAFILE > $WORK_FILE
    gawk -f $ORAFILE_AWK $ORAFILE > $WORK_FILE

   return 
}

check_for_errors()
{
#    ---------------------------------------------------------
#    Filter out all messages within the oracle file that match
#    yy/mm/dd hh for this run.  Then filter only those matches
#    which are of concern to the database administrator (i.e.
#    matches in the WORRIES file.  Then remove inconsequential
#    errors (i.e., those which appear in the NO_WORRIES file.
#    Finally, exclude those already in the filtered_err file
#    from a previous run.
#    ---------------------------------------------------------

if [ -f $WORRIES -a -f $NO_WORRIES ]
then
   cat $WORK_FILE | fgrep -f $WORRIES | fgrep -v -f $NO_WORRIES | fgrep -v -f $FERR_FILE > $NEW_FERR_FILE
#   cat $WORK_FILE | egrep -f $WORRIES | egrep -v -f $NO_WORRIES | egrep -v -f $FERR_FILE > $NEW_FERR_FILE
else
     $MAILTO "Scan_Orafile In ${ORACLE_SID} Failed - Missing file:  Worries or No-Worries" $EMPTY_FILE $MAILTO_C
fi
    
#    -----------------------------------------------------------
#    If the temporary file is not empty, then we know that there
#    are messages within the alertlog that should be examined.
#    Alert the database administrator(s) by email.
#    -----------------------------------------------------------

if [ -s $NEW_FERR_FILE ] 
then
  cat $NEW_FERR_FILE >> $FERR_FILE
  $MAILTO "Problems in ${ORACLE_SID} server $ORAFILE" $NEW_FERR_FILE $MAILTO_C
fi

   return 

}

##################################################################
# process starts here
##################################################################

   change_day

   init_process

   pre_process_alert_log

   check_for_errors

####################################################################
# process ends here
####################################################################

