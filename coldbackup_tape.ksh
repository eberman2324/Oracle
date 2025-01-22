#!/bin/ksh
# -----------------------------------------------------------
#    File: coldbackup_tape.ksh
#  Author: Mark Lantsberger 03/16/2005
# Purpose: A KORN shell script to run a cold backup of database files to tape
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
#  Setup environment
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

. $SCRIPTS/runsql_lib.ksh $ORACLE_SID

typeset -i DebugLevel
if [[ $DebugLevel == 9 ]]
then
   set -o xtrace
else
   set +o xtrace
fi  

#------------------------------------------------------------
#  File name variables
#------------------------------------------------------------
PROCESSNAME=coldbackuptape
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
function run_sqlplus_shutdown
{
   $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOFSQL >> $OUTFILE 2>> $ERRFILE
shutdown immediate;
exit;
EOFSQL

   if [ $? != 0 ]
   then
      echo "Error in shutdown DB At `date`" >> $ERRFILE
      ERRFLAG=1
      return
   fi 

}

###------------------------------------------------
function run_sqlplus_startup
{
   $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOFSQL >> $OUTFILE 2>> $ERRFILE
startup;
exit;
EOFSQL

   if [ $? != 0 ]
   then
      echo "Error in starting DB At `date`" >> $ERRFILE
      ERRFLAG=1
      return
   fi 

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
      ### Run coldbackupbatchtape function from runsql_lib.ksh
      coldbackupbatchtape $BATCHSIZE $RETPER

      if [ -s $RUNTHIS ]
      then
         run_sqlplus_shutdown

         # Runs cbackup_all.ksh script
         $RUNTHIS

         # Sleep till cold back is complete
         SEARCHFOR="bpbackup"
         sleep 180
         process_running=`ps -ef | grep $SEARCHFOR | grep $ORACLE_SID | egrep -v grep | wc -l`
         while (( $process_running > 0 ))
         do
              process_running=`ps -ef | grep $SEARCHFOR | grep $ORACLE_SID | egrep -v grep | wc -l`
              echo "Coldbackup running... " $process_running " Batches are running "
              sleep 60
         done  

         run_sqlplus_startup
      fi 
   fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

#clean_up


