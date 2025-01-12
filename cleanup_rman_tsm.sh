#!/bin/bash
################################################################################################################3333333333333
#  This script will unregister a DBID from recovery catalog and cleanup tsm backups.
#
#  usage: $ . cleanup_rman_tsm.sh  <target_db_name> <target_dbid>  
#
#
#  Maintenance Log:
#  version 1.0 02/2018      R. Ryan     New Script 
#          1.1 03/2018      R. Ryan     Made changes enabling the scheduling of the Job in the future.
#          1.2 07/2019      R. Ryan     Allowed for Multiple cleanups of the same database name.
#          2.0 01/2020      R, Ryan     Extended support to container databases
#          2.1 01/2020      R, Ryan     Resolved insufficient shared pool sire error when starting cleanup instance for 19c
#          2.2 09/2020      R, Ryan     Corrected defect in updating oratab.
#          2.3 10/2020      R, Ryan     Set the RCATPASS variable since it was removed from oraenv
#          3.0 01/2021      R. Ryan     Modified scrript to accomodate new joint CVS/Aetna standard
#          3.1 05/2022      R. Ryan     Modified scrript to add spu count to dummy instance startup to avoid sga too small errors in large cpu count VMs
#          3.2 11/2022      R. Ryan     Modified scrript for BT
#
#############################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

function strip {
    local STRING=${1#$"$2"}
    echo ${STRING%$"$2"}
}

update_oratab () {

cp /etc/oratab /tmp/oratab_$DATEVAR
#sed -i "/${PSU}/d" /etc/oratab
grep -v ${ORATAB_NAME}: /etc/oratab > /tmp/oratab.new
cp /tmp/oratab.new /etc/oratab
rm /tmp/oratab.new

}

# End of functions


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/cleanup_rman_tsm_$1_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 2 ]; then
  log_console "Usage: $0  target_db_name dbid"
  log_console Parms: $*
  exit 1
fi

log_console "Start tsm cleanup of $1 DBID $2 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

export ORATAB_NAME=$1
export ORACLE_SID=$1
export DBID=$2
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`
if [[ $1 == CDB[0-9][0-9]C_del* ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9]_del* ]] ; then
  DBNAME=$SERVER_NAME
else
  export DBNAME=`echo $1 | cut -d _ -f1`
fi



#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

log_console ' '
export ORAENV_ASK=NO
. oraenv >> $LOGFILE

case $RCATDB in
RCATDEV)
  RCATHOST=xoraclddbw1d
;;
RCATPROD)
  RCATHOST=xoraclddbm1p
;;
esac
export RCATPASS=`fetch_db_bt.bash.x -a DBA -r "create recovery catalog" -P $DBNAME -h $RCATHOST  -s $RCATDB -p 1524 2>/dev/null`


#------------------------------------------------------------
#  Build/Start Dummy Cleanup Instance
#------------------------------------------------------------

log_console "Starting dummy CLEANUP instance........"
export ORACLE_SID=CLEANUP
echo DB_NAME=$ORACLE_SID > $ORACLE_HOME/dbs/init_for_cleanup.pfile
echo cpu_count=2 >> $ORACLE_HOME/dbs/init_for_cleanup.pfile
echo SGA_TARGET=1G >> $ORACLE_HOME/dbs/init_for_cleanup.pfile

sqlplus -S  <<EOF  >>$LOGFILE
connect / as sysdba
whenever sqlerror exit failure 1
startup nomount pfile=?/dbs/init_for_cleanup.pfile
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Instance Startup Failed"
  exit 1
else
  log_console  "Instance Startup Successful"
fi

#----------------------------------------------------------
#  Cleaup  RMAN catalog/tsm
#----------------------------------------------------------

cat << label2 > runthis_1.rman
connect catalog ${DBNAME}/${RCATPASS}@${RCATDB};
list incarnation;
set dbid=${DBID};
list backup summary;
delete backup of database;
delete backup of archivelog all;
delete backup of controlfile;
list backup summary;
quit

label2

cat << label3 > runthis_2.rman
connect catalog ${DBNAME}/${RCATPASS}@${RCATDB};
list db_unique_name all;
set dbid=${DBID};
unregister database;
list db_unique_name all;
quit

label3

log_console " "
log_console "Starting RMAN/TSM cleanup........."
rman target / <<EOF >>$LOGFILE
@runthis_1.rman
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> RMAN/TSM cleanup failed"
else
  log_console "RMAN/TSM cleanup successful, unregistering DBID ${DBID} from catalog....."
rman target / <<EOF >>$LOGFILE
@runthis_2.rman
EOF
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> RMAN ungresiter failed"
  else
    log_console "Unregister of DBID ${DBID} from catalog successful"
  fi
fi

rm runthis_1.rman
rm runthis_2.rman

#------------------------------------------------------------
# Shutdown Dummy Cleanup Instance
#------------------------------------------------------------

log_console "Shutting down dummy cleanup instance........"
export ORACLE_SID=CLEANUP

sqlplus -S  <<EOF  >>$LOGFILE
connect / as sysdba
shutdown immediate;
quit;
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Instance Shutdown Failed"
  exit 1
else
  log_console  "Instance Shutdown Successful"
  if [[ "$ORATAB_NAME" == *"_del"* ]]; then
    update_oratab
  fi
  rm $ORACLE_HOME/dbs/init_for_cleanup.pfile
fi




log_console " "
log_console "Cleanup of RMAN/TSM for $ORACLE_SID  DBID $DBID  complete on  `uname -svrn` at `date` using $0 "
exit 0

