#!/bin/ksh

USAGE="Usage:  scan_oracle.ksh arg1 (where arg1 is ORACLE_SID name)"

#
# ---------------------------------------------------------
#  file:    scan_oracle.ksh
#
#  author:  Mark Lantsberger   Oracle version
#           Cindy Wiech        major enhancements
#
#  purpose: A Korn Shell script for warning the Database Administrator 
#           about potential problems with the Oracle Alert Logs & 
#           Trace Files.
#
#  useage:  This script accepts one argument, the Oracle Database name.
#           If this is supplied, it will be used to call oraprof to 
#           set the Oracle Environemnt variables.
#           If the Oracle SID is not supplied, the script will terminate.
#
#  process: This script creates an output file that lists all the Oracle
#           output files to be scanned for error conditions called 
#           orafile_list.dat.  This file lists the alert log for this
#           instance and any trace files that have been created since
#           last time this script has run.
#           After this list has been created the script reads through
#           this file and calls scan_orafile.ksh to do the actual
#           scan for Oracle errors.
#
#  output files:
#           This script uses the $ORACLE_BASE/admin/$ORACLE_SID/bdump
#           where it places all output files.  It will create the 
#           following output files:  
#           filtered_err  (file containing oracle error messages found
#                          in either the alert log or trace files)
#           new.file (used for date comparison within the script)
#           new_filtered (new filtered error list)
#           orafile.tmp (reformatted alert log or trace file)
#           orafile_list.dat (list of files to be scanned)
#
# change history:
# 01/30/2011 TS Revised For 11g
# 04/06/2007 TS Revised For BroadSpire Environment
# 10/05/2017 EB Revised For HealhEdge
# 07/09/2024 EB Revised For HealhEdge RACONE


SCRIPTS=/oradb/app/oracle/local/scripts/monitor
ORACLE_BASE=/oradb/app/oracle

if [ $1 ]
then   
     # Set DataBase Name
     DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`   
     ps -ef | grep pmon | grep -v grep > pmon.out
     ps -ef| grep ${DBName} pmon.out |awk '{ print $8 }' | tail -c 10 > instname.out
     DBName=`cat instname.out`
     export ORAENV_ASK=NO
     ORACLE_SID=${DBName}
     DB=$1
     CLUSTERNAME=`cat clustername`

       

fi

export DB_UNIQUE_NAME=${DB}_${CLUSTERNAME} 
export BDUMP=${ORACLE_BASE}/diag/rdbms/${DB_UNIQUE_NAME}/${ORACLE_SID} | tr "[:upper:]" "[:lower:]"/trace;
export UDUMP=${ORACLE_BASE}/diag/rdbms/${DB_UNIQUE_NAME}/${ORACLE_SID} | tr "[:upper:]" "[:lower:]"/trace;



ALERTLOG=${BDUMP}/alert_${ORACLE_SID}.log

UDUMP_TRACE=${UDUMP}/

BDUMP_TRACE=${BDUMP}/

ORAFILE_LIST=${BDUMP}/orafile_list.dat

NEW_FILE=${BDUMP}/new.file

#########################################################
# function definitions start here
########################################################

init_process()
{

if [ -f $ORAFILE_LIST ]
then
   rm $ORAFILE_LIST
fi 

echo $ALERTLOG > $ORAFILE_LIST

}


first_time()
{
find $UDUMP_TRACE -name "${LC_SID}*.trc" -exec ls {} \; >> $ORAFILE_LIST

find $BDUMP_TRACE -name "${LC_SID}*.trc" -exec ls {} \; >> $ORAFILE_LIST
}


check_for_trace_files()
{

LC_SID=`echo $ORACLE_SID |tr "[:upper:]" "[:lower:]"`

#look in the udump and bdump directory for trace files
#created since the last time this script ran

if [ ! -f $NEW_FILE ] 
then first_time
else
  find $UDUMP_TRACE -name "${LC_SID}*.trc" -newer $NEW_FILE -exec ls {} \; >> $ORAFILE_LIST
  find $BDUMP_TRACE -name "${LC_SID}*.trc" -newer $NEW_FILE -exec ls {} \; >> $ORAFILE_LIST
fi

touch $NEW_FILE

}

call_scan_orafile()
{

if [ ! -f $ORAFILE_LIST ]
then
   echo "No Oracle Files To Scan"
   return
fi 

while read ORAFILE ;do
   $SCRIPTS/scan_orafile.ksh $ORAFILE $ORACLE_SID
done < $ORAFILE_LIST


}
##################################################################
# process starts here
##################################################################


init_process

check_for_trace_files

call_scan_orafile

   
####################################################################
# process ends here
####################################################################

