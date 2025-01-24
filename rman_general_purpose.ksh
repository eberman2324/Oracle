#!/bin/ksh
# -----------------------------------------------------------
#    File: rman_general_purpose.ksh
#  Author: Mark Lantsberger 01/31/2007
# Purpose: A KORN shell script to run an RMAN hot backup of database files 
#
#          The process can be disabled by creating an entry "general_purpose"
#          in the file "disable_a_process" located in $SCRIPTS/batch/backup directory.
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
USAGE="Usage: rman_general_purpose.ksh arg1 arg2 arg3 (arg1=ORACLE_SID, arg2=RMAN_SID arg3=cmdfile name)"
#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 3
   then
     echo $USAGE
     return 1
   fi

   export ORACLE_SID=$1
   export RMAN_SID=$2
   export CMDFILE=$3

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
PROCESSNAME=rman_general_purpose
OUTPUT_PATH=$INSTANCE_OUTPUTS/rman_backups
LOGFILE="$INSTANCE_OUTPUTS/rman_backups/`date +%Y%m%d_%T`_$CMDFILE.log"
DISABLEDCHECK=$SCRIPTS/backup/disable_a_process

#export rmanpass=`cat ~/INFO/.passwd.rman`
export rmanpass=${ORACLE_SID}namr

#export syspass=`cat ~/INFO/.passwd.$ORACLE_SID`

#------------------------------------------------------------
#  Functions for processing
#------------------------------------------------------------

###------------------------------------------------
clean_up()
{
   ########## remove logs older than 30 days #############################
   find $OUTPUT_PATH/*.log -type f -mtime +3  -exec rm -r {} \;


   return $?
}

###------------------------------------------------
run_process()
{
   set +o xtrace
   # Execute the process
   COUNTEM=`cat $DISABLEDCHECK | grep $PROCESSNAME | wc -l`
   if [ $COUNTEM == 1 ]
   then
      echo "Run is disabled"
   else
      ### Run RMAN stored script
 rman  target / catalog ${ORACLE_SID}/${rmanpass}@$RMAN_SID cmdfile=${SCRIPTS}/backup/$CMDFILE log=$LOGFILE

   fi

   return $?
}

###------------------------------------------------
run_error_check()
{
export ERROR_COUNT=`pg $LOGFILE|grep 'ERROR MESSAGE STACK'|wc -l`

#
#####################################################################
# If error found, page DBA.  If no error found, submit validate job.
#####################################################################
#
if [ $ERROR_COUNT -gt 0 ]
  then
    MailIt "$ORACLE_SID - RMAN level0 backup failed." $EMPTY_FILE dba email
#    MailIt "$ORACLE_SID - RMAN level0 backup failed." $EMPTY_FILE dba pager
  else
    MailIt "$ORACLE_SID - RMAN level0 backup successful." $EMPTY_FILE dba email
#    if [ `ps -ef|grep -v grep|grep validate_backup|wc -l` -gt 0 ]
#       then
#       exit 0
#    else
#       echo "DR02 RMAN level0 backup verified: "  $DATE > $LOG
#       mailx -s "DR02 RMAN validate job submitted. " 8884505487@skytel.com <$LOG
#       nohup /usr/local/oracle/bin/rman/rman.ksh validate_backup.rman > /usr/local/oracle/log/rman/validate_backup.nohup.out 2>&1 &
#    fi

fi

   return $?
}
###====================================================================
### Process Starts Here

run_process
run_error_check

clean_up


