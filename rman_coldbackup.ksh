#!/bin/ksh
# -----------------------------------------------------------
#    File: rman_coldbackup.ksh
#  Author: Mark Lantsberger 01/31/2007
# Purpose: A KORN shell script to run an RMAN hot backup of database files 
#
#          The process can be disabled by creating an entry "coldbackup"
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
USAGE="Usage: rman_coldbackup.ksh arg1 arg2 (arg1=ORACLE_SID, arg2=RMAN_SID)"
#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   export ORACLE_SID=$1
   export RMAN_SID=$2

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
PROCESSNAME=rmancoldbackup
#OUTPUT_PATH=$INSTANCE_OUTPUTS/rman_backups
LOGFILE="$INSTANCE_OUTPUTS/rman_backups/`date +%Y%m%d_%T`_rman_coldbackup.log"
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
   rm -f $XXXX

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
 rman  target / catalog ${ORACLE_SID}/${rmanpass}@$RMAN_SID cmdfile=${SCRIPTS}/backup/rman_coldbackup_cmdfile log=$LOGFILE

##rman  target / catalog '$ORACLE_SID/$RMAN_SIDnamr@$RMAN_SID' log '$OUTPUT' << EOF 
##run {execute global script full_db_backup;}
##EOF
##exit

   fi

   return $?
}

###====================================================================
### Process Starts Here

run_process

#clean_up


