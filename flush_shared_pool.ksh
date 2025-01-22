#!/bin/ksh
# -----------------------------------------------------------
#    File: flush_shared_pool.ksh
#  Author: Mark Lantsberger 4/9/2001
# Purpose: A KORN shell script to flush the shared pool
#          if usage > 90%.
#
#          The process can be disabled by creating an entry "flush_shared_pool"
#          in the file "disable_a_process" located in $SCRIPTS/misc directory.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT                         WHO 
#  10/19/2001  2.1      Add code to lock process.       MSL
# 
# -----------------------------------------------------------
USAGE="Usage: flush_shared_pool.ksh arg1 (arg1=ORACLE_SID)"
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

#------------------------------------------------------------
# Setup environment
#------------------------------------------------------------ 
. $HOME/setup_env.ksh $ORACLE_SID
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
#    ------------------------------------------------------------
PROCESSNAME=flush_shared_pool
DISABLEDCHECK=$SCRIPTS/misc/disable_a_process
LOCKPROCESS=$SCRIPTS/misc/lock_${PROCESSNAME}_${ORACLE_SID}

#    ------------------------------------------------------------
#    Check if process is already running (locked)
#    ------------------------------------------------------------
if [ -f $LOCKPROCESS ]
then
   echo "Process is already running."
   exit
else
   echo "LOCK FLUSH SHARED POOL PROCESS" > $LOCKPROCESS
fi                    

#
#  Functions for processing
#

###------------------------------------------------
clean_up()
{
   rm -f $XXXX

   return $?
}

#
#  Run Processes
#
###------------------------------------------------
run_process()
{
   # Execute Processes
   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
   else
      ### Run oltp_flush_shared_pool function from runsql_lib.ksh
      oltp_flush_shared_pool
   fi

   #    ------------------------------------------------------------
   #    Unlock process 
   #    ------------------------------------------------------------
   if [ -f $LOCKPROCESS ]
   then
      rm $LOCKPROCESS
   fi                    

   return $?
}

###====================================================================
### Process Starts Here
#set -o xtrace

run_process

#clean_up


