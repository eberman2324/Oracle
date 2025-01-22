#!/bin/ksh
# ---------------------------------------------------------
#  file:    scan_alertlog.ksh
#
#
#  purpose: A Korn Shell script for warning the Database Administrator 
#           about potential problems with the oracle database.
#
#  Setup:   This script accepts one argument....the instance name.
#           If this is passed, it will be used to call .sybase to 
#           set the following variables:
#                $WORRIES    - name/location of the worries file
#                $NO_WORRIES - name/location of the no_worries file
#           If the server name is not passed, the script assumes the
#           variables have already been set.
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
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT               WHO 
#  10/22/2001  2.0      Legacy free.          MSL
#  10/15/2002           send o/p from setup to /dev/null JJP            
#                       (otherwise info going to mail and filling up)
#  08/13/2003  2.01      changed work file location to be in bdump directory
#                       preventing issues when 2 databases being scanned
#                       at the same time      MEJ
#------------------------------------------------------------
###########################################################################
#------------------------------------------------------------
USAGE="Usage: scan_alertlog.ksh arg1 (arg1=ORACLE_SID)"
# Ensure Oracle Database Name Was Passed
#------------------------------------------------------------
if [ $1 ]
then
    ORACLE_SID=$1
else
    echo $USAGE
    exit
fi

export ORACLE_SID
export DIAGNOSTIC_DEST=$2
#------------------------------------------------------------
# Setup environment
#------------------------------------------------------------
### Determine platform script is running on
if [ "`uname -m`" = "sun4u" ] ; then
   ORATAB=`find /var -name oratab -print 2> /dev/null`
else
   ORATAB=`find /etc -name oratab -print 2> /dev/null`
fi

### Determine scripts locaation from oratab file
cat $ORATAB | while read LINE
do
    case $LINE in
        \#*)            ;;      #comment-line in oratab
        *)
        ORATAB_SID=`echo $LINE | awk -F: '{print $1}' -`
        if [ "$ORATAB_SID" = '*' ] ; then
               ORATAB_SID=""
        fi

        if [ "$ORACLE_SID" = "$ORATAB_SID" ] ; then
#          Get Script Path from oratab file.
           FS_FOR_SCRIPTS=`echo $LINE | awk -F: '{print $4}' -`
        fi
    ;;
    esac
done

export SCRIPTS=$FS_FOR_SCRIPTS/aetna/scripts

. $SCRIPTS/setupenv.ksh $ORACLE_SID

typeset -i DebugLevel
if [[ $DebugLevel == 9 ]]
then
   set -o xtrace
else
   set +o xtrace
fi

#    ------------------------------------------------------------
#    File names
#    ------------------------------------------------------------
PROCESSNAME=scan_alertlog
DISABLEDCHECK=$SCRIPTS/misc/disable_a_process
#DISABLEDCHECK=$SCRIPTS/monitor/disable_a_process

if [ -d ${ORACLE_HOME}/admin/$CONTEXT_NAME/bdump ]
then
     export ALERTDIR=${ORACLE_HOME}/admin/$CONTEXT_NAME/bdump
else
     #export ALERTDIR=/u27/oracle/$ORACLE_SID/diag/rdbms/"$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')"/$ORACLE_SID/trace
     #export ALERTDIR=${ORACLE_BASE}/admin/${ORACLE_SID}/bdump
     export ALERTDIR=$DIAGNOSTIC_DEST/diag/rdbms/"$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')"/$ORACLE_SID/trace
fi

ALERTLOG=${ALERTDIR}/alert_${ORACLE_SID}.log     
WORK_FILE=${ALERTDIR}/alertlog_${ORACLE_SID}.tmp 
WORRIES=${SCRIPTS}/monitor/worries
NO_WORRIES=${SCRIPTS}/monitor/no_worries
FERR_FILE=${ALERTDIR}/filtered_err     
FERR_TEMP1=${ALERTDIR}/filtered_temp1  
NEW_FERR_FILE=${ALERTDIR}/new_filtered 
SCANLOG_AWK=${SCRIPTS}/monitor/scan_alertlog.awk

#  FUNCTIONS For Processing
#

###------------------------------------------------
check_if_process_disabled()
{

   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
      exit
   fi

   return $?
}

###------------------------------------------------
init_process()
{
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

   return $?
}

###------------------------------------------------
change_day()
{
   if [ $DAYNUM == "01" ]
   then
      DAYNUM=" 1"
   fi

   if [ $DAYNUM == "02" ]
   then
      DAYNUM=" 2"
   fi

   if [ $DAYNUM == "03" ]
   then
      DAYNUM=" 3"
   fi

   if [ $DAYNUM == "04" ]
   then
      DAYNUM=" 4"
   fi

   if [ $DAYNUM == "05" ]
   then
      DAYNUM=" 5"
   fi

   if [ $DAYNUM == "06" ]
   then
      DAYNUM=" 6"
   fi

   if [ $DAYNUM == "07" ]
   then
      DAYNUM=" 7"
   fi

   if [ $DAYNUM == "08" ]
   then
      DAYNUM=" 8"
   fi

   if [ $DAYNUM == "09" ]
   then
      DAYNUM=" 9"
   fi

   return $?
}

###------------------------------------------------
pre_process_alert_log()
{

   awk -f $SCANLOG_AWK $ALERTLOG > $WORK_FILE

   return $?
}

###------------------------------------------------
check_for_errors()
{
#    ---------------------------------------------------------
#    Filter out all messages within the errorlog that match
#    yy/mm/dd hh for this run.  Then filter only those matches
#    which are of concern to the database administrator (i.e.
#    matches in the WORRIES file.  Then remove inconsequential
#    errors (i.e., those which appear in the NO_WORRIES file.
#    ---------------------------------------------------------
 
if [ -f $WORRIES -a -f $NO_WORRIES -a -f $WORK_FILE ]
then
   grep "$DAY $MON $DAYNUM" $FERR_FILE > $FERR_TEMP1
   if [ -s $FERR_TEMP1 ]
   then
      cat $WORK_FILE | grep "$DAY $MON $DAYNUM" | egrep -f $WORRIES | egrep -v -f $NO_WORRIES | egrep -v -f $FERR_TEMP1 > $NEW_FERR_FILE

   else
      echo "XXXXXXXXXXXXXXX" > $FERR_TEMP1
      cat $WORK_FILE | grep "$DAY $MON $DAYNUM" | egrep -f $WORRIES | egrep -v -f $NO_WORRIES | egrep -v -f $FERR_TEMP1 > $NEW_FERR_FILE

   fi 

else
     MailIt "Scan_Log Failed in ${ORACLE_SID} - Missing file:  Worries, No-Worries and Alertlog name/location." $EMPTY_FILE dba email
fi
    
#    -----------------------------------------------------------
#    If the temporary file is not empty, then we know that there
#    are messages within the alertlog that should be examined.
#    Alert the database administrator(s) by email.
#    -----------------------------------------------------------

if [ -s $NEW_FERR_FILE ] 
then
  cat $NEW_FERR_FILE >> $FERR_FILE
  MailIt "Problems in ${ORACLE_SID} server alert log $ALERTLOG" $NEW_FERR_FILE dba  email
  MailIt "Problems in ${ORACLE_SID} server alert log $ALERTLOG" $NEW_FERR_FILE $ORACLE_SID pager
fi

if [ -f $NEW_FERR_FILE ] 
then
   rm $NEW_FERR_FILE
fi

   return $?
}

###------------------------------------------------
clean_up()
{

   rm $FERR_TEMP1
   rm $WORK_FILE

   return $?
}

##################################################################
# Process starts Here

   check_if_process_disabled

   change_day

   init_process

   pre_process_alert_log

   check_for_errors

   clean_up
