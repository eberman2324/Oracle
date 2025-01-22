#!/bin/ksh
# -----------------------------------------------------------
#    File: coldbackup.ksh
#  Author: Mark Lantsberger 06/20/2002
# Purpose: A KORN shell script to run a cold backup of database files 
#
#          The process can be disabled by creating an entry "coldbackup"
#          in the file "disable_a_process" located in $SCRIPTS/batch/backup directory.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#
# For change information see comment in PVCS
#
#
###########################################################################
# -----------------------------------------------------------
USAGE="Usage: coldbackup.ksh arg1 arg2 arg3 (arg1=ORACLE_SID, arg2=Batchsize, arg3=Retention Days)"
#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 3
   then
     echo $USAGE
     return 1
   fi

   export ORACLE_SID=$1
   typeset -i BATCHSIZE=$2
   export RETPER=$3 

#------------------------------------------------------------
#  Setup debugging
#------------------------------------------------------------ 

   set_debugging

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------ 
   ### Determine platform script is running on
   if [ "`uname -m`" = "sun4u" ] ; then
      ORATAB=`find /var -name oratab -print 2> /dev/null`
   else
      ORATAB=`find /etc -name oratab -print 2> /dev/null`
   fi

   ### Determine scripts location from oratab file
   export FS_FOR_SCRIPTS=`awk -F: "/^${ORACLE_SID}:/ {print \\$4; exit}"\
                    $ORATAB 2>/dev/null`

   export SCRIPTS=$FS_FOR_SCRIPTS/aetna/scripts

. $SCRIPTS/runsql_lib.ksh $ORACLE_SID

#------------------------------------------------------------
#  File name variables
#------------------------------------------------------------
PROCESSNAME=coldbackup
RUNTHIS=$INSTANCE_OUTPUTS/backups/COLDBKP$DATETIME/cbackup_all.ksh
OUTPUT=$SCRIPTS/out/xxx_${ORACLE_SID}.out
DISABLEDCHECK=$SCRIPTS/backup/disable_a_process
ERRFILE=$INSTANCE_OUTPUTS/backups/COLDBKP$DATETIME/cbackup.err

#------------------------------------------------------------
#  Functions for processing
#------------------------------------------------------------

###------------------------------------------------
function clean_up
{
   rm -f $XXXX

   return $?
}


###------------------------------------------------
function run_process
{

   # Execute the process
   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
   else
      ### Run coldbackupbatch function from runsql_lib.ksh
      coldbackupbatch $BATCHSIZE $RETPER

      if [ -s $RUNTHIS ]
      then
         ### Run run_db_shutdown function from runsql_lib.ksh
         run_db_shutdown

         # Runs cbackup_all.ksh script
         $RUNTHIS

         # Sleep till cold back is complete
         SEARCHFOR="cbackup_batch"
         echo "Checking for cold backup scripts running..."
         sleep 100
         process_running=`ps -ef | grep $SEARCHFOR | grep $ORACLE_SID | egrep -v "grep cbackup_batch" | wc -l`
         while (( $process_running > 0 ))
         do
              process_running=`ps -ef | grep $SEARCHFOR | grep $ORACLE_SID | egrep -v "grep cbackup_batch" | wc -l`
              echo "Coldbackup running... " $process_running " Batches are running "
              sleep 60
         done  

         ### Run run_db_startup function from runsql_lib.ksh
         run_db_startup
      fi 
   fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

#clean_up


