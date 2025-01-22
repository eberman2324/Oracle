#!/bin/ksh
# -----------------------------------------------------------
#    File: hotbackup_plus_archivelog.ksh
#  Author: Mark Lantsberger 11/09/2001
# Purpose: A KORN shell script to run a hot backup of database files 
#
#          The process can be disabled by creating an entry "hotbackup"
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
USAGE="Usage: hotbackup.ksh arg1 arg2 arg3 (arg1=ORACLE_SID, arg2=Batchsize, arg3=Retention Days)"
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
   RETPER=$3 

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
PROCESSNAME=hotbackup
BACKUPDIR=$INSTANCE_OUTPUTS/backups/HOTBKP$DATETIME
RUNTHIS=$BACKUPDIR/hbackup_all.ksh
OUTPUT=$SCRIPTS/out/xxx_${ORACLE_SID}.out
DISABLEDCHECK=$SCRIPTS/backup/disable_a_process
BACKUPSTART=`date "+%m/%d/%Y %H:%M:%S"`
FINALBATCHSCRIPT=$BACKUPDIR/hbackup_email_wait.ksh

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
      ### Run hotbackupbatch function from runsql_lib.ksh
      hotbackupbatch $BATCHSIZE $RETPER

      ### Modify the hot backup scripts to add in an archivelog backup
      add_arch_backup

      if [ -s $RUNTHIS ]
      then
         $RUNTHIS
         echo "$PROCESSNAME run at: $DATETIME" 
      fi 
   fi

   return $?
}
###------------------------------------------------
add_arch_backup()
{
   ### Add line to the script for the last batch that will 
   ### backup the archivelogs from the beginning of the backup
   mv ${FINALBATCHSCRIPT} ${FINALBATCHSCRIPT}.orig
   cat ${FINALBATCHSCRIPT}.orig | grep -v "MailIt" > ${FINALBATCHSCRIPT}
   echo "$SCRIPTS/backup/archbackup.ksh \"$BACKUPSTART\" \"$BACKUPDIR\" ">> ${FINALBATCHSCRIPT}
   grep "MailIt" ${FINALBATCHSCRIPT}.orig  >> ${FINALBATCHSCRIPT}
   chmod u+x ${FINALBATCHSCRIPT}
}

###====================================================================
### Process Starts Here

run_process

#clean_up


