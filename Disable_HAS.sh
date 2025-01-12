#!/bin/bash
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs

LOGFILE=$LOGDIR/Disable_has_$1_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

MSGFILE=/tmp/temp.msg
TMPFILE=/tmp/temp.info
log_console "Start Disable HAS  `uname -svrn` at `date` using $0 $*"
log_console " "
log_console "Review log file $LOGFILE for details"
log_console " "

#########################################################################################################################################
#echo "to: LuddyM@Aetna.com" > $MSGFILE
echo "to: LuddyM@Aetna.com , RyanR2@Aetna.com " > $MSGFILE
#########################################################################################################################################
export "`date +%b%d_%H%M%S`"
export L_BINDIR=$BASE/local/bin
export L_SQLDIR=$BASE/local/sql
export L_RPTDIR=$BASE/local/reports
export L_LOGDIR=$BASE/local/logs
PATH=$PATH:/usr/local/bin
TMPDIR=/tmp
export ORAENV_ASK=NO
export ORACLE_SID=+ASM
. oraenv
#############################################################################################################

#$ORACLE_HOME/bin/sqlplus -s /nolog << EOF
#connect / as sysdba
#@$L_BINDIR/test.sql
#EOF

log_console "About to disable HAS"

log_console "  "
log_console "About to disable HAS on machine `hostname` "
log_console " "
echodo crsctl disable has   | tee -a $LOGFILE
if [ ${PIPESTATUS[0]} -eq 0 ]; then
  log_console " " 
  log_console "HAS has been disabled!"
  log_console " "
else
  log_console " "
  log_console "HAS Disable has failed!!!!"
  log_console " "
fi

log_console "Confirming:"
echodo /bin/cat /etc/oracle/scls_scr/*/$STD_HAS_USER/ohasdstr | tee -a $LOGFILE

#########################################################################################################################################
#
echo "subject: HAS on `hostname` is disabled!" 	>> $MSGFILE
echo "MIME-Version: 1.0"                        >> $MSGFILE
echo "Content-Type: text/html"                  >> $MSGFILE
echo "Content-Disposition: inline"              >> $MSGFILE
echo '<HTML><BODY><PRE>'                        >> $MSGFILE
#/bin/cat $INNFILE                               >> $MSGFILE
/bin/cat $LOGFILE                               >> $MSGFILE
echo '</PRE></BODY></HTML>'                     >> $MSGFILE
#
/usr/sbin/sendmail -t < $MSGFILE
########################################################################################
rm $MSGFILE
log_console " "
log_console "Disable HAS  complete  `uname -svrn` at `date` using $0 "
log_console " "

