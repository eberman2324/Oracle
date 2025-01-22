#!/bin/ksh
# -----------------------------------------------------------
#    File: dbverify.ksh
#  Author: Mark Lantsberger 8/8/2001
# Purpose: A KORN shell script to dbv all database files 
#
#          The process can be disabled by creating an entry "dbverify"
#          in the file "disable_a_process" located in $SCRIPTS/batch/misc directory.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT               WHO 
#  For change information see comment in PVCS
#                        
###########################################################################
# -----------------------------------------------------------
USAGE="Usage: dbverify.ksh arg1 (arg1=ORACLE_SID)"
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
PROCESSNAME=dbverify
RUNTHIS=$SCRIPTS/dynamic/db_verify_${ORACLE_SID}.ksh
OUTPUT=$SCRIPTS/out/db_verify_${ORACLE_SID}.out
DISABLEDCHECK=$SCRIPTS/misc/disable_a_process

#------------------------------------------------------------
#  Functions for processing
#------------------------------------------------------------

###------------------------------------------------
clean_up()
{
   rm -f $XXXX

   return $?
}

###------------------------------------------------
run_process()
{

   # Execute the process
   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
   else
      ### Run db_verify function from runsql_lib.ksh
      db_verify

      if [ -s $RUNTHIS ]
      then
         $RUNTHIS
         echo "$PROCESSNAME run at: $DATETIME" 
         COUNTEM=`cat $OUTPUT | grep "Corrupt block" | wc -l`
         if [ $COUNTEM >= 0 ]
         then
             ### Run MailIt function from setupenv.ksh
             MailIt "$ORACLE_SID - Datafile has a corrupt block" $EMPTY_FILE $ORACLE_SID email
             MailIt "$ORACLE_SID - Datafile has a corrupt block" $EMPTY_FILE $ORACLE_SID pager
         fi
      fi 
   fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

#clean_up


