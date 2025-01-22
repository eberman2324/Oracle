#!/bin/ksh
#set -o xtrace

# -----------------------------------------------------------
#    File: monitorDB.ksh
#  Author: Mark Lantsberger 2/28/98
# Purpose: A KORN shell script to monitor the database and inform
#          the DBA's of potential problems.
#
#                         C H A N G E S
#
# ---------------------------------------------------------------------------
#  DATE        VERSION  COMMENT                                           WHO 
#  10/19/2001  2.0      Initial version (uses stored procedure).          MSL
#
# ---------------------------------------------------------------------------
USAGE="Usage: monitorDB.ksh arg1 (arg1=ORACLE_SID)"
#------------------------------------------------------------
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

SYSTEM=`echo $ORACLE_SID | cut -c1-2`

#------------------------------------------------------------
# Setup environment
#------------------------------------------------------------
. /boraw1du01/aetna/scripts/setupenv.ksh $ORACLE_SID
. $SCRIPTS/runsql_lib.ksh $ORACLE_SID

typeset -i DebugLevel
if [[ $DebugLevel == 9 ]]
then
   set -o xtrace
else
   set +o xtrace
fi

#    ------------------------------------------------------------
#    File names
#
#    ------------------------------------------------------------
MONITOR_TEMP=$SCRIPTS/monitor/monitor.temp
MONITOR=$SCRIPTS/monitor/monitorDB.out
MONITOR1=$SCRIPTS/monitor/rpt1.out
MONITOR2=$SCRIPTS/monitor/rpt2.out
MONITOR3=$SCRIPTS/monitor/rpt3.out
MONITOR4=$SCRIPTS/monitor/rpt4.out
MONITOR5=$SCRIPTS/monitor/rpt5.out
MONITOR6=$SCRIPTS/monitor/rpt6.out
MONITOR1_HOURLY=$SCRIPTS/monitor/rpt1_hourly.out
MONITOR1_DAILY=$SCRIPTS/monitor/rpt1_daily.out
MONITOR2_DAILY=$SCRIPTS/monitor/rpt2_daily.out
MONITOR3_DAILY=$SCRIPTS/monitor/rpt3_daily.out
MONITOR4_DAILY=$SCRIPTS/monitor/rpt4_daily.out
MONITOR5_DAILY=$SCRIPTS/monitor/rpt5_daily.out

#
#  Functions for processing
#

###------------------------------------------------
clean_up()
{
   rm -f $MONITOR
   rm -f $MONITOR1
   rm -f $MONITOR2
   rm -f $MONITOR3
   rm -f $MONITOR4
   rm -f $MONITOR5
   rm -f $MONITOR6
#  rm -f $MONITOR1_HOURLY
   rm -f $MONITOR1_DAILY
   rm -f $MONITOR2_DAILY
   rm -f $MONITOR3_DAILY
   rm -f $MONITOR4_DAILY
   rm -f $MONITOR5_DAILY

   #
   # age off old monitor output files
   #
#   find "${SCRIPTS}/monitor/out" -type f -mtime ${RETDAYS} -exec rm -f {} \;

   return $?
}


###------------------------------------------------
run_sql()
{
#set -o xtrace

   COUNTEM=`ps -ef | grep monitorDB.sql | egrep -v grep | egrep -v ksh | egrep -v sh | wc -l`

   if [ $COUNTEM == 0 ]
   then
      sqlplus generic/sql @${SCRIPTS}/monitor/SQL/monitorDB.sql $ORACLE_SID > /dev/null
   fi

   return $?
}

#
# Mail Monitor Reports 
#

###------------------------------------------------
mail_monitor_outputs()
{
#
#  Send reports at crontab interval 
#
   cat $MONITOR1 $MONITOR2 $MONITOR3 $MONITOR4 $MONITOR5 > $MONITOR

   if [ -s $MONITOR ]
   then
      MailIt "${ORACLE_SID} Alerts" $MONITOR $ORACLE_SID email
   fi

   if [ -s $MONITOR3 ]
   then
      MailIt "${ORACLE_SID} Invalid Objects Over Threshold" $MONITOR3 $ORACLE_SID pager
   fi 

   if [ -s $MONITOR6 ]
   then
      cat $MONITOR6 >> $MONITOR1_HOURLY
   fi

#
#  Send reports at the top of each hour 
#

  if [ $MIN == "00" ]
    then
       if [ -s $MONITOR1_HOURLY ]
       then
          sort -u $MONITOR1_HOURLY | egrep -v USER > $MONITOR_TEMP
          MailIt "${ORACLE_SID} Connection Violations" $MONITOR_TEMP security email
          rm $MONITOR1_HOURLY $MONITOR_TEMP
      fi
   fi
#
#  Send reports at 9 AM 
#


  if [ $HOUR == "09" -a $MIN == "00" ]
  then
     if [ -s $MONITOR3_DAILY ]
     then
        MailIt "${ORACLE_SID} Inactive Connections From Prior Day" $MONITOR3_DAILY ifscustomer email
        MailIt "${ORACLE_SID} Inactive Connections From Prior Day" $MONITOR3_DAILY ifsmanager email
      fi
   fi
#
#  Send reports at 12 AM
#
   if [ $HOUR == "12" -a $MIN == "00" ]
   then
      if [ -s $MONITOR2_DAILY ]
      then
         MailIt "${ORACLE_SID} Information" $MONITOR2_DAILY $ORACLE_SID email
      fi

      if [ -s $MONITOR4_DAILY ]
      then
         MailIt "${ORACLE_SID} Information" $MONITOR4_DAILY $ORACLE_SID email
      fi

   fi

#
#  Send reports at 10 PM
#
   if [ $HOUR == "22" -a $MIN == "00" ]
   then
      if [ -s $MONITOR1_DAILY ]
      then
         MailIt "${ORACLE_SID} Information" $MONITOR1_DAILY ifsprogmgr email
         MailIt "${ORACLE_SID} Information" $MONITOR1_DAILY ifsqa email
      fi

   fi

   return $?
}

###====================================================================
### Process Starts Here

   run_sql

   mail_monitor_outputs

   clean_up


