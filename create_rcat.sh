#!/bin/bash
######################################################################################################
#  create_catalog.ksh is executed to pre create recovery catalogs  
#
#  usage: $ . create_catalog.sh   <catalog owner>  
#
#
#  Maintenance Log:
#  03/2013          R. Ryan     New Script 
#  01/2016      1.1 R. Ryan     Added log file 
#  03/25/2016   1.2 R. Ryan     Changed default disk backups to compressed
#  08/18/2016   1.3 R. Ryan     Changed Catalog owner id to use the TRUSTED_ID_NO_EXPIRE profile
#  09/27/2016   2.0 R. Ryan     Added strong password support and tpam integration
#  10/06/2016   2.1 R. Ryan     Corrected active database check. Removed the need to enter rcat instance
#  10/25/2016   2.2 R. Ryan     changed edmz url to pum
#  11/14/2016   2.3 R. Ryan     source bash_profile to avoid RCTDB issues
#  02/20/2017   2.4 R. Ryan     Changed DISK group from DATA to DATA_01 to conform to standards after the move of RCATDEV to Next Gen.
#  03/13/2017   2.5 R. Ryan     Removed rate specification on channel configuration.
#  10/08/2018   2.6 R. Ryan     Changed the recovery window from 30 days to 14 days for non-prod and 21 days for prod.
#  01/09/2019   2.7 R. Ryan     Eliminated the need to enter the SYS password for the RCAT database. Password is now retrieved from PUM
#  01/16/2020   3.0 R. Ryan     Added logic to register the database in an existing recovery catalog or creates the recovery catalog if 
#                               it does not exist.
#  01/19/2021   4.0 R. Ryan     Modified scrript to accomodate new joint CVS/Aetna standard
#  11/07/2022   4.1 R. Ryan     Modified scrript to support ddboost.
#
#####################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Function : Create recovery catalog tablespace and owner, create reocvery catalog in rman
create_catalog () {

#--------------------------------------------------------
#   Generate Catalog Owner password
#---------------------------------------------------------
CAT_PASS=(`sqlplus -s / as sysdba<<eof1
set pages 0
set head off
set feed off
whenever sqlerror exit 1
select randompass from dual;
exit;
eof1`)

if [ $? -ne 0 ] ; then
  log_console "Random Password Generateion Failed"
  log_console " "
  exit 1
fi

cat << label1 > $ORACLE_BASE/admin/$ORACLE_SID/sql/create_cat_${CAT_OWN}.sql
set echo on
CREATE TABLESPACE $CAT_OWN
    DATAFILE '+DATA_01' SIZE 250M AUTOEXTEND ON NEXT 1M MAXSIZE 1000M
    EXTENT MANAGEMENT LOCAL UNIFORM SIZE 64K
    LOGGING
    ONLINE
    SEGMENT SPACE MANAGEMENT AUTO
/
CREATE USER $CAT_OWN IDENTIFIED BY "$CAT_PASS"
    DEFAULT TABLESPACE $CAT_OWN
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON $CAT_OWN
    PROFILE TRUSTED_ID_NO_EXPIRE
    ACCOUNT UNLOCK
/
GRANT RECOVERY_CATALOG_OWNER TO $CAT_OWN WITH ADMIN OPTION
/
ALTER USER $CAT_OWN DEFAULT ROLE RECOVERY_CATALOG_OWNER
/

label1

cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_cat_${CAT_OWN}.sql > $SQLPATH/runthis.sql

log_console "Start create recovery catalog owner and tablespace on $RCATDB"

sqlplus -S sys/$CAT_DB_PASS@$RCATDB as sysdba <<EOF >>$LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Create recovery catalog owner and tablespace failed in sqlplus"
  exit 1
else
  log_console  "Create recovery catalog owner and tablespace successful"
fi

rm $SQLPATH/runthis.sql

rman target / <<EOF >>$LOGFILE
connect catalog ${CAT_OWN}/${CAT_PASS}@$RCATDB;
create catalog;
quit
EOF
if [ $? -gt 0 ] ; then
  log_console " ERROR ---> Create recovery catalog failed in rman"
  exit 1
else
   log_console "Create recovery catalog successful"
fi

}

# Function : register database in recovery catalog
register_database () {
if [ ${RCATDB} = 'RCATDEV' ] ; then
  cat << label2 > $ORACLE_BASE/admin/$ORACLE_SID/rman/create_cat_${CAT_OWN}.rman
  connect catalog ${CAT_OWN}/${CAT_PASS}@$RCATDB;
  register database;
  CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
  CONFIGURE DEFAULT DEVICE TYPE TO 'SBT_TAPE';
  CONFIGURE CONTROLFILE AUTOBACKUP ON;
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F';
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE SBT_TAPE TO '%F'; # default
  CONFIGURE DEVICE TYPE 'SBT_TAPE' PARALLELISM 2 BACKUP TYPE TO BACKUPSET;
  CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO COMPRESSED BACKUPSET;
  CONFIGURE CHANNEL DEVICE TYPE 'SBT_TAPE' PARMS 'BLKSIZE=1048576,SBT_LIBRARY=$STD_DBMS_DIR/app/ddboost/lib/libddobk.so,ENV=(STORAGE_UNIT=$STD_STORAGE_UNIT,BACKUP_HOST=$STD_BACKUP_HOST,ORACLE_HOME=$ORACLE_BASE/admin/$ORACLE_SID/oracle_home)' format './%d/bk_%d_%I_%T/%U';
  CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO 'SBT_TAPE';
  quit

label2
else
  cat << label2 > $ORACLE_BASE/admin/$ORACLE_SID/rman/create_cat_${CAT_OWN}.rman
  connect catalog ${CAT_OWN}/${CAT_PASS}@$RCATDB;
  register database;
  CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 21 DAYS;
  CONFIGURE DEFAULT DEVICE TYPE TO 'SBT_TAPE';
  CONFIGURE CONTROLFILE AUTOBACKUP ON;
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F';
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE SBT_TAPE TO '%F'; # default
  CONFIGURE DEVICE TYPE 'SBT_TAPE' PARALLELISM 2 BACKUP TYPE TO BACKUPSET;
  CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO COMPRESSED BACKUPSET;
  CONFIGURE CHANNEL DEVICE TYPE 'SBT_TAPE' PARMS 'BLKSIZE=1048576,SBT_LIBRARY=$STD_DBMS_DIR/app/ddboost/lib/libddobk.so,ENV=(STORAGE_UNIT=$STD_STORAGE_UNIT,BACKUP_HOST=$STD_BACKUP_HOST,ORACLE_HOME=$ORACLE_BASE/admin/$ORACLE_SID/oracle_home)' format './%d/bk_%d_%I_%T/%U';
  CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO 'SBT_TAPE';
  quit

label2
fi



cat  $ORACLE_BASE/admin/$ORACLE_SID/rman/create_cat_${CAT_OWN}.rman > runthis.rman
log_console "Creating recovery catalog please wait........"

rman target / <<EOF >>$LOGFILE
@runthis.rman
EOF

if [ $? -gt 0 ] ; then
  log_console " ERROR ---> Create recovery catalog failed in rman"
  exit 0
else
   log_console "Create recovery catalog successful"
fi

rm runthis.rman
}

#  Function : Store Catalog Owner password in TPAM
store_password () {
log_console "Adding Catalog owner password to BT"
log_console "ADD API for BT is not yet available, request rcat password to be added to BT"
##ssh -i ~/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com AddAccount --AccountName RCAT_${RCATDB}_$CAT_OWN --SystemName NMA_Oracle  --password "${CAT_PASS}"
##if [ $? -ne 0 ] ; then
##   log_console "TPAM password update failed for RCAT_${RCATDB}_$CAT_OWN"
##   exit 0
##else
## log_console "TPAM ${CAT_OWN} password add complete"
##   log_console "Password can be found in TPAM at RCAT_${RCATDB}_$CAT_OWN under system NMA_Oracle"
##fi
}

# End of Functions


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/create_rcat_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  cat_owner"
  log_console Parms: $*
  exit 1
fi

log_console "Start create catalog $1  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "


# Check to see if Oracle Instance is active
ps -ef | grep pmon_$1$ | grep -v grep | grep -v $1[0-z]
if test $? -gt 0; then
  log_console "Oracle Instance is not active...try later or SID is invalid"
  exit 1
fi

export ORACLE_SID=$1
#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------
export ORAENV_ASK=NO
. oraenv

mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/rman
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql

export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`
if [[ $ORACLE_SID == CDB[0-9][0-9]C ]] || [[ $ORACLE_SID == C[0-9][0-9][H,R,P][N,P][0-9][0-9] ]] ; then
  CAT_OWN=$SERVER_NAME
else
  CAT_OWN=$1
fi

unset CAT_DB_PASS
#-----------------------------------------------------------------------------
# Retrieve RCAT sys passwaord from tpam
#-----------------------------------------------------------------------------
case $RCATDB in
RCATDEV)
  RCATHOST=xoraclddbw1d
;;
RCATPROD)
  RCATHOST=xoraclddbm1p
;;
esac
export CAT_DB_PASS=`fetch_db_bt.bash.x -a DBA -r "create recovery catalog" -P sys -h $RCATHOST  -s $RCATDB -p 1524 2>/dev/null`

#prompt="Enter $RCATDB sys password:"
#
#    while IFS= read -p "$prompt" -r -s -n 1 char
#            do
#                    if [[ $char == $'\0' ]]
#                            then
#                                    break
#                    fi
#                    prompt='*'
#                    CAT_DB_PASS+="$char"
#            done

log_console " "
sqlplus -S sys/$CAT_DB_PASS@$RCATDB as sysdba<<eof1 >> $LOGFILE
whenever sqlerror exit 1
exit;
eof1

if [ $? -gt 0 ]; then
  log_console "Invalid Password, check BT to ensure the correct password is stored for xoraclddbw1d/m1p_${RCATDB}_SYS"
  exit 1
fi

#-------------------------------------------------------
#  Check if Recovery Catalog exists
#-------------------------------------------------------
export CAT_COUNT=$LOGDIR/CAT_COUNT_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select count(*) from dba_users where username=upper('$CAT_OWN');
exit;" | sqlplus -s sys/${CAT_DB_PASS}@${RCATDB} as sysdba > $CAT_COUNT

export CAT_COUNT=$(tail -1 $CAT_COUNT |sed -e 's/ //g')

if [ $CAT_COUNT -eq 0 ] ; then
  create_catalog
  register_database
  store_password
else
  export CAT_PASS=`fetch_db_bt.bash.x -a DBA -r "create recovery catalog" -P $CAT_OWN -h $RCATHOST  -s $RCATDB -p 1524 2>/dev/null`
  export DB_ID_LIST=$LOGDIR/DB_ID_LIST_$ORACLE_SID.log
  echo "set echo off ver off pages 0 trims on head off feed off
  select listagg(dbid,'_') within group (order by dbid) dbids from ${CAT_OWN}.rc_database;
  exit;" | sqlplus -s sys/${CAT_DB_PASS}@${RCATDB} as sysdba > $DB_ID_LIST

  export DB_ID_LIST=$(tail -1 $DB_ID_LIST |sed -e 's/ //g' | tr '_' ' ')

  DBID=(`sqlplus -s / as sysdba<<eof1
  @get_dbid.sql
eof1`)

  DB_ID_FOUND='N'
  for RC_DBID in $DB_ID_LIST
   do
     if [ $DBID -eq $RC_DBID ] ; then
       DB_ID_FOUND='Y'
       echo dbid found
     fi  
   done

  if [ $DB_ID_FOUND = 'Y' ] ; then
    log_console "Database is already registered in recovery catalog, no action taken"
  else
    register_database
  fi
fi


log_console "Review log file $LOGFILE for details"
log_console "create catalog $2 complete  `uname -svrn` at `date` using $0"
log_console


exit 0

