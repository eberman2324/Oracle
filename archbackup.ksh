#!/bin/ksh
# -----------------------------------------------------------
#    File: archbackup.ksh
# Purpose: A KORN shell script designed to be run as part of 
#          the hotbackup_plus_archivelog.ksh script that will
#          identify and copy all of the archivelogs beginning
#          at the specified time to the present time to the
#          specified location. 
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
USAGE="Usage: archbackup.ksh arg1 arg2 (arg1=Backup StartTime [MM/DD/YYYY HH24:MI:SS], arg2=Backup Directory)"
#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   BACKUPSTART=$1
   BACKUPDIR=$2

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
PROCESSNAME=archbackup

#------------------------------------------------------------
#  Functions for processing
#------------------------------------------------------------

###------------------------------------------------
clean_up()
{
   echo Cleanup
   return $?
}

###------------------------------------------------
run_process()
{

   #  Back Up archivelogs covering the backup period
   list_archivelogs
   tar -L $BACKUPDIR/archivelog_list.lst -cf - | gzip -c > $BACKUPDIR/archivelogs.tar.gz
   return $?
}

list_archivelogs()
{
   sqlplus -S /nolog <<-EOF
	set heading off
	set trimspool on
	set echo off
	set termout off
	set feedback off
	set verify off
	set pagesize 0
	whenever sqlerror exit failure
	connect / as sysdba
	alter system archive log current;
        spool $BACKUPDIR/archivelog_list.lst
	select name from v\$archived_log where 
		first_time >= to_date('$BACKUPSTART', 'MM/DD/YYYY HH24:MI:SS')
		or
		next_time >= to_date('$BACKUPSTART', 'MM/DD/YYYY HH24:MI:SS') ;
	spool off
	EOF
  
}
###====================================================================
### Process Starts Here
run_process

clean_up


