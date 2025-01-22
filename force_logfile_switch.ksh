#!/bin/ksh
# -----------------------------------------------------------
#    File: force_logfile_switch.ksh
#  Author: Mark Lantsberger 4/9/2001
# Purpose: A KORN shell script to initiate an archive logfile
#          switch every half hour.
#
#          The process can be disabled by creating a 
#          file "disable_a_process" in the $SCRIPTS/misc directory.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT               WHO 
#  For change information see comment in PVCS
# 
###########################################################################
# -----------------------------------------------------------
USAGE="Usage: force_logfile_switch.ksh arg1 (arg1=ORACLE_SID)"
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

#    ------------------------------------------------------------
#    File names
#
#    ------------------------------------------------------------
PROCESSNAME=force_logfile_switch
DISABLEDCHECK=$SCRIPTS/misc/disable_a_process

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
#  Run Process
#
###------------------------------------------------
run_process()
{
   # Execute the process
   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
   else
      ### Run oltp_force_logfile_switch function from runsql_lib.ksh
      oltp_force_logfile_switch
   fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

#clean_up


