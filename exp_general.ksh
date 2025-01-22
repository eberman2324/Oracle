#!/bin/ksh
# -----------------------------------------------------------
#    File: exp_general.ksh
#  Author: Mark Lantsberger 02/5/2008
# Purpose: A KORN shell script to run an RMAN hot backup of database files 
#
#          The process can be disabled by creating an entry "general_purpose"
#          in the file "disable_a_process" located in $SCRIPTS/export directory.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT                                     WHO 
#
# For change information see comment in PVCS
#
###########################################################################
# -----------------------------------------------------------
USAGE="Usage: exp_general.ksh arg1 arg2 arg3 (arg1=ORACLE_SID arg2=parfile arg3=export filename)"
#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 3
   then
     echo $USAGE
     return 1
   fi

   export ORACLE_SID=$1
   export PARFILE=$2
   export DUMPFILE=$3

#------------------------------------------------------------
# Get MTIME (default is 14)
#------------------------------------------------------------
if [ "$4" ]
then
   MTIME=$4
else
   # MODIFIED default is 60 days
   MTIME=+60
fi

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

set_date

typeset -i DebugLevel
if [[ $DebugLevel == 9 ]]
then
   set -o xtrace
else
   set +o xtrace
fi  

#------------------------------------------------------------
#  Misc. variables
#------------------------------------------------------------
PROCESSNAME=exp_for_backup
if [ -d $INSTANCE_OUTPUTS ]
then
   OUTPUT_PATH=$INSTANCE_OUTPUTS/export
else
   OUTPUT_PATH=$INSTANCE_EXPORTS/export
fi
EXPLOGFILE=exp_`date +%Y%m%d_%H%M%S`.log
EXPDUMPFILE=exp_${DUMPFILE}_`date +%Y%m%d_%H%M%S`.dmp

#export expimppass=`cat ~/INFO/.passwd.expimp`
export expimppass=testload

#export syspass=`cat ~/INFO/.passwd.$ORACLE_SID`

#------------------------------------------------------------
#  Functions for processing
#------------------------------------------------------------

###------------------------------------------------
clean_up()
{
   ########## remove logs older than 60 days and remove export dumps older than 60 days #############################
   find $OUTPUT_PATH/*.log -type f -mtime $MTIME  -exec rm -r {} \;
   find $OUTPUT_PATH/*.dmp* -type f -mtime $MTIME  -exec rm -r {} \;


   return $?
}

###------------------------------------------------
run_process()
{
   set +o xtrace
   # Execute the process

       cat ${ORACLE_BASE}/.${ORACLE_SID}.pw | exp PARFILE=${SCRIPTS}/export/$PARFILE FILE=${OUTPUT_PATH}/$EXPDUMPFILE LOG=${OUTPUT_PATH}/${EXPLOGFILE}
       run_error_check ${OUTPUT_PATH}/${EXPLOGFILE}
       gzip ${OUTPUT_PATH}/$EXPDUMPFILE
   return $?
}

###------------------------------------------------
run_error_check()
{
   USAGE="Usage: run_error_check arg1  (arg1=log file)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   LOGFILE=$1

export ERROR_COUNT=`pg $LOGFILE|grep 'error(s)'|wc -l`

#
#####################################################################
# If error found, page DBA.  If no error found, submit validate job.
#####################################################################
#
if [ $ERROR_COUNT -gt 0 ]
  then
	 MailIt "$ORACLE_SID - expdp failed." $EMPTY_FILE dba email
    #MailIt "$ORACLE_SID - expdp (BACKUP) failed." $EMPTY_FILE $ORACLE_SID email
    #MailIt "$ORACLE_SID - expdp (BACKUP) failed." $EMPTY_FILE $ORACLE_SID pager
fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

clean_up


