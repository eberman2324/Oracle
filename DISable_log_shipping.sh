#!/bin/bash
######################################################################################################
#
#  usage: $ . DISable_transport.sh  <ORACLE_SID>
#
#  Descrioption:  This script is called to disable log shipping on the primary database in a DataGuard  
#                 Configuration.   The script can be executed on either the primary or standby server.
#
#  Version		When		Who		What
#  ------------------   --------------  --------------  ---------------------------------------------
#  1.0 			11/24/2015	M. Luddy	Created script (hardcode unique name for now)
#  2.0 			06/22/2018	R. Ryan 	Made script generic 
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
NOW=`/bin/date '+%m-%d-%Y-%H%M%S'`
LOGFILE=$LOGDIR/DISable_transport__${NOW}__$1.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0 Oracle SID "
  log_console Parms: $*
  exit 1
fi

log_console "Start Disable Log Shipping $1 on  `uname -svrn` at `date` using $0"
log_console " "
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z]
if test $? -eq 1; then
  ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z]>> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  not active...start it before enable log shipping"
  exit 1
fi
log_console " "

export ORACLE_SID=$1
log_console ' '
export ORAENV_ASK=NO
. oraenv >> $LOGFILE

PRIMARY_DB=`dgmgrl -echo / "show configuration" | grep 'Primary database' | cut -d - -f1 |  sed 's/^[ \t]*//;s/[ \t]*$//'`
#####################################################################################################

dgmgrl -echo / "show configuration" | tee -a $LOGFILE
echo -e "\n=================================================================================================================================\n" | tee -a $LOGFILE

dgmgrl -echo / "show database verbose '$PRIMARY_DB'" | tee -a $LOGFILE
echo -e "\n=================================================================================================================================\n" | tee -a $LOGFILE

echo -e "ABOUT TO      edit database '$PRIMARY_DB' set state=transport-off       \n\n" | tee -a $LOGFILE
dgmgrl -echo / "edit database '$PRIMARY_DB' set state=transport-off" | tee -a $LOGFILE
echo -e "\n=================================================================================================================================\n" | tee -a $LOGFILE

dgmgrl -echo / "show database verbose '$PRIMARY_DB'" | tee -a $LOGFILE
echo -e "\n=================================================================================================================================\n" | tee -a $LOGFILE

#/bin/cat $LOGFILE
echo -e "\n\n\n"
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
echo -e "  Look at LAST line: \n"
/bin/grep -i 'Intended State' $LOGFILE
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 

$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<EOF
spool $LOGFILE append;
@check_dg_parms_nosp
EOF
log_console "End Disable Log Shipping $1 on  `uname -svrn` at `date` using $0"
#####################################################################################################
