#!/bin/bash
##############################################################################################################
#  clone_sb_db.sh is executed to clone the latest Standard Build database   
#
#  usage: $ . clone_sb_db.sh  <dbms_version> <target_db_name>  <target_db_port> <char_set> <nchar_set>
#
#
#  Maintenance Log:
#  1.0  06/2015      R. Ryan     New Script 
#  1.1  09/2015      R. Ryan     Fixed check to see f SBDB is available
#  1.2  09/2015      R. Ryan     Corrected port check
#  1.3  11/2015      R. Ryan     delete audit snap shot dbid after clone completes
#  1.4  12/2015      R. Ryan     Add database and Listener to OEM
#                                Check to ensure the Standard Build database is at the requested PSU level
#  1.5  02/04/16     R. Ryan     Changed to accomodate Oracle's PSU new naming standard
#                                Removed  REDOC_01 disk group from standard build
#                                Corrected JAVA version issue with EMCLI calls
#  2.0  02/12/16     R. Ryan     Added character set support
#  2.1  03/03/16     R. Ryan     Removed IND_01 disk group from srvctl add database command.
#  2.2  03/14/16     R. Ryan     Create symbolic link from $ORACLE_BASE/admin/$ORACLE_SID tp $ORACLE_HOME
#  2.3  03/25/16     R. Ryan     Add recompile of type ku\$_radm_fptm_t if nls character set is UTF8
#                                as described in doc ID 1641033.1
#  2.4  03/30/16     R. Ryan     corrected symbolic link check 
#  2.5  03/31/16     R. Ryan     Changed tns entry for new database to ${ORACLE_SID}_${SERVER_NAME}  to avoid 
#                                ldap conflicts
#  2.6  05/17/16     R. Ryan     Corrected PSU check logic
#  2.7  08/19/16     R. Ryan     Ensure there are 3 controlfiles.  It REDOC exists place 3rd control file there
#                                else place it in FLASH
#  3.0  09/20/16     R. Ryan     Add 11g support
#  3.1  10/06/16     R. Ryan     Corrected instance active check 
#  3.2  10/06/16     R. Ryan     Corrected rman auxiliary database connection for 11g databases
#                                Corrected JAVA version issue ith EMCLI and 11g
#  3.3  01/26/17     R. Ryan     Added scheduling of log purge and trim Job in OEM
#  3.4  02/20/17     R. Ryan     Enabled Block Change Tracking
#  3.5  03/13/17     R. Ryan     Modified ORACLEDBA_SYSATEM variable due to EMCLDPRD database move to xoraclddbm1p
#  3.6  03/24/17     R. Ryan     Added Standard Build comment in OEM
#  3.7  10/02/17     R. Ryan     Remove old AWR DBIDs and set snapshot retention to 30 days
#  4.0  11/29/17     R. Ryan     Added EBS support
#  5.0  11/29/18     R. Ryan     18c support
#  5.1  03/18/19     R. Ryan     Modified script to add database to HAS using database homw rather than ASM home 
#  5.2  03/18/19     R. Ryan     Modified script to add OEM contact of "dba oracle" on the database and listener for Datacenter Pageing   
#  5.3  01/19/20     R. Ryan     Added recovery catalog create
#  5.4  03/01/20     R. Ryan     Corrected issue with 18c and above starting an auxiliary database with default SGA size.
#  6.0  01/19/21     R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#########################################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo "$*" | tee -a $LOGFILE
}

# Function : schedule log purge
schedule_purge () {

log_console " "
log_console "Scheduling Purge and Trim Job in OEM"

case ${SERVER_NAME: -1} in
    p)
     ORACLEDBA_HOST='xoraclddbm1p'
     ORACLEDBA_SID='EMCLDPRD'
    ;;
    *)
     ORACLEDBA_HOST='xoraclddbw1d'
     ORACLEDBA_SID='EMCLDDEV'
    ;;
esac

ORACLEDBAPASS=`fetch_db_bt.bash.x -a DBA -r "create  database" -P oracledba -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`
PUPPETPASS=`fetch_db_bt.bash.x -a DBA -r "create  database" -P puppet -h $ORACLEDBA_HOST  -s $ORACLEDBA_SID -p 1525 2>/dev/null`

echo target_list=${ORACLE_SID}_${SERVER_NAME}:oracle_database > /tmp/job_prop_$ORACLE_SID.txt

$ORACLE_BASE/product/emcli/emcli logout | tee -a $LOGFILE
$ORACLE_BASE/product/emcli/emcli login  -username=oracledba -password=$ORACLEDBAPASS | tee -a $LOGFILE

$ORACLE_BASE/product/emcli/emcli create_job_from_library -lib_job=PURGE_AND_TRIM_LOGS -name=PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} -owner=ORACLEDBA -input_file=property_file:/tmp/job_prop_${ORACLE_SID}.txt | tee -a $LOGFILE

if [ ${PIPESTATUS[0]}  -gt 0 ] ; then
  log_console "Purge and Trim job scheduling failed for ${DB_UNIQUE_NAME},  Please schedule Job manually"
else
  log_console "Purge and Trim job has been scheduled for ${DB_UNIQUE_NAME} with default retentions and log size set in OEM library JOB PURGE_AND_TRIM_LOGS"
  log_console "The Job will starting from today based on the default schedule set in OEM library JOB PURGE_AND_TRIM_LOGS."
  log_console "Reschedule JOB PURGE_AND_TRIM_LOGS_${DB_UNIQUE_NAME} to update the default values."
fi

$ORACLE_BASE/product/emcli/emcli logout | tee -a $LOGFILE
$ORACLE_BASE/product/emcli/emcli login  -username=puppet -password=$PUPPETPASS | tee -a $LOGFILE
rm /tmp/job_prop_$ORACLE_SID.txt
log_console " "
}
#End of functions

source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/clone_db_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 5 ]; then
  log_console "Usage: $0  dbms_version target_db_name target_db_port char_set nchar_set"
  log_console Parms: $*
  exit 1
fi

log_console "Start Clone SB to $2  `uname -svrn` at `date` using $0 $*"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "

# Check to see if Oracle Instance is active
ps -ef | grep pmon_$2$ | grep -v grep | grep -v $2[0-z] 
if test $? -eq 0; then
  ps -ef | grep pmon_$2$ | grep -v grep | grep -v $2[0-z] >> $LOGFILE
  log_console " "
  log_console "Oracle Instance is  active...drop it before attempting clone"
  exit 1
fi

#------------------------------------------------------
# Validate schar nchar set
#------------------------------------------------------
VALID_CHAR=`echo WE8ISO8859P15 WE8ISO8859P1 WE8MSWIN1252 US7ASCII AL32UTF8`
VALID_NCHAR=`echo UTF8 AL16UTF16`

for CHAR_SET in $VALID_CHAR
  do
    if [ $4 == $CHAR_SET ] ; then
      IS_VALID_CHAR='TRUE'
      break
    else
      IS_VALID_CHAR='FALSE'
    fi
  done

if [ $IS_VALID_CHAR == 'FALSE' ]; then
  log_console " "
  log_console "NLS_CHARACTER set entered is invalid"
  log_console "Valid character sets are $VALID_CHAR"
  exit 0
else
  log_console "$CHAR_SET is a vaild nls_characterset, continuing with clone......"
fi
  
for NCHAR_SET in $VALID_NCHAR
  do
    if [ $5 == $NCHAR_SET ] ; then
      IS_VALID_NCHAR='TRUE'
      break
    else
      IS_VALID_NCHAR='FALSE'
    fi
  done

if [ $IS_VALID_NCHAR == 'FALSE' ] ; then
  log_console " "
  log_console "NLS_NCHAR_CHARACTER entered is invalid"
  log_console "Valid NCHAR character sets are $VALID_NCHAR"
  exit 0
else
  log_console "$NCHAR_SET is a valid nls_nchar_characterset, continuing with clone......"
fi

#----------------------------------------------------
# Check if disk groups exist and have sufficient space
#------------------------------------------------------
export ORACLE_SID=+ASM
export ORAENV_ASK=NO
 
. oraenv >> $LOGFILE


freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'${STD_DATA_DG#?}'"
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi
if [ "${freespace[0]}" -eq "1"  ]; then
  log_console "Disk Group ${STD_DATA_DG#?} exists, continuing with clone....."
  if [ ${freespace[1]} -lt 6000 ]; then
    log_console "Insufficient free space exists in disk group ${STD_DATA_DG#?} to complete the clone, ensure there is at least 6gb available in ${STD_DATA_DG#?}"
    exit 1
  else
    log_console "Disk Group ${STD_DATA_DG#?} has sufficient free space, continuing with clone......"
  fi
else
  log_console "Disk Group ${STD_DATA_DG#?} is not found, ensure DATA_01 exists before attempting clone."
  exit 1
fi

freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'${STD_FRA_DG#?}'"
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi

if [ "${freespace[0]}" = "1" ]; then
  log_console "Disk Group ${STD_FRA_DG#?} exists, continuing with clone......"
else
  log_console "Disk Group ${STD_FRA_DG#?} is not found, ensure ${STD_FRA_DG#?}1 exists before attempting clone......"
  exit 1
fi
  
freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'${STD_REDO1_DG#?}'"
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi

if [ "${freespace[0]}" = "1" ]; then
  log_console "Disk Group ${STD_REDO1_DG#?} exists, continuing with clone....."
  if [ ${freespace[1]} -lt 300 ]; then
    log_console "Insufficient free space exists in disk group ${STD_REDO1_DG#?} to complete the clone, ensure there is at least 50mb available in ${STD_REDO1_DG#?}"
    exit 1
  else
    log_console  "Disk Group ${STD_REDO1_DG#?} has sufficient free space, continuing with clone......"
  fi
else
  log_console " Disk Group ${STD_REDO1_DG#?} is not found, ensure ${STD_REDO1_DG#?} exists before attempting clone."
  exit 1
fi

freespace=(`sqlplus -s / as sysdba<<eof1
@get_freespace.sql "'${STD_REDO2_DG#?}'"
eof1`)
if [ $? -gt 0 ]; then
  log_console "Disk Group Checked failed,  make sure ASM is available."
  exit 1
fi

if [ "${freespace[0]}" = "1" ]; then
  log_console "Disk Group ${STD_REDO2_DG#?} exists, continuing with clone......"
  if [ ${freespace[1]} -lt 300 ]; then
    log_console "Insufficient free space exists in disk group ${STD_REDO2_DG#?} to complete the clone, ensure there is at least 50mb available in ${STD_REDO2_DG#?}"
    exit 1
  else
    log_console "Disk Group ${STD_REDO2_DG#?} has sufficient free space, continuing with clone......"
  fi
else
  log_console "Disk Group ${STD_REDO2_DG#?} is not found, ensure ${STD_REDO2_DG#?} exists before attempting clone."
  exit 1
fi

#freespace=(`sqlplus -s / as sysdba<<eof1
#@get_freespace.sql "'REDOC_01'"
#eof1`)
#if [ $? -gt 0 ]; then
#  log_console "Disk Group Checked failed,  make sure ASM is available."
#  exit 1
#fi

#if [ "${freespace[0]}" = "1" ]; then
#  log_console "Disk Group REDOC_01 exists, continuing with clone......."
#  if [ ${freespace[1]} -lt 50 ]; then
#    log_console "Insufficient free space exists in disk group REDOC_01 to complete the clone, ensure there is at least 50mb available in REDOC_01"
#    exit 1
#  else
#    log_console "Disk Group REDOC_01 has sufficient free space, continuing with clone......"
#    export CNT_FILE_3_LOC=+REDOC_01
#  fi
#else
#  log_console "Disk Group REDOC_01 is not found, using FLASH_01 for third  control file" 
#  export CNT_FILE_3_LOC=+FLASH_01
#fi
. ~oracle/.bash_profile >/dev/null

export ORACLE_SID=$2
export VERSION=$1
export PORT=$3
export MAJOR_REL=`echo $VERSION | tr -d . | cut -c1-2`


if [ -d ${STD_DBMS_DIR}/app/oracle/product/${VERSION} ]; then
  log_console "Oracle DBMS software version $VERSION is installed, continuing with clone........"
else
  log_console "Oracle DBMS software version $VERSION is not intalled."
  exit 1
fi

if [ -d ${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1/nls/data/9idata ] ; then
  log_console "E-Business Suite Oracle Home has been detected"
  log_console "Database will be created from the E-Business Suite Standard Build"
#  ps -ef | grep pmon | grep -v +ASM | grep -v grep >/dev/null
#  if test $? -eq 0; then
#    log_console "The following databases have been found to be executing on this VM:"
#    log_console "`ps -ef | grep pmon | grep -v +ASM | grep -v grep`"
#    log_console "Only one database per VM is permitted for E-Business Suite systems"
#    exit 1
#  fi
  if [ `echo $VERSION | cut -c1-2` -gt 12 ]; then
    export SBDB=SBE`echo $VERSION | cut -c1-2`00
  else
    export SBDB=SBE`echo $VERSION | tr -d . | cut -c1-5`
  fi
else
  if [ `echo $VERSION | cut -c1-2` -gt 12 ]; then
    export SBDB=SB`echo $VERSION | cut -c1-2`00
  else
    export SBDB=SB`echo $VERSION | tr -d . | cut -c1-5`
  fi
fi

netstat -tlen | grep :$PORT >/dev/null 2>&1
if [ $? -eq 0 ]; then
  log_console "Selected port is in use, please free the port or select another"
  exit 1
fi

#-----------------------------------------------------------------------------
# Retrieve SBDB sys passwaord from tpam
#-----------------------------------------------------------------------------
export password=`fetch_db_bt.bash.x -a DBA -r "checks" -P sys -h xoragdbw2d -s SB1900 -p 1550 2>/dev/null`

export TNS_ADMIN=${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1/network/admin
cat << label1 > $SQLPATH/connect_to_sbdb.sql
connect dbsnmp/drugs2gogo@$SBDB ;
connect sys/${password}@$SBDB as sysdba ;
label1
chmod 700 $SQLPATH/connect_to_sbdb.sql

sqlplus -S /nolog <<EOF  >>$LOGFILE
whenever sqlerror exit 1
@connect_to_sbdb.sql
exit;
EOF

if [ $? -eq 0 ]; then
  log_console "Standard Build database $SBDB is available, continuing with clone......."
else
  log_console "Standard Build database is not available, make sure $SBDB is available and sys password is correct then retry clone"
  exit 1
fi

#----------------------------------------------------------------------------------
# Check PSU Level of SB database
#----------------------------------------------------------------------------------
export ORACLE_HOME=$ORACLE_BASE/product/$VERSION/db_1
export PSU_LEVEL=$LOGDIR/psu_level_$ORACLE_SID.log
case $MAJOR_REL in
11)
  export DEST_PSU_LEVEL=`$ORACLE_BASE/product/$VERSION/db_1/OPatch/opatch lsinventory | grep -i 'Database Patch Set Update'| grep $VERSION |tr ')' '(' | cut -d'(' -f2`
  echo "set echo off ver off pages 0 trims on head off feed off
  with a as (select XMLTYPE(XML_INVENTORY) patch_output from OPATCH_XML_INV)
  select max(x.patch_id)
    from a,
         xmltable('InventoryInstance/patches/*'
            passing a.patch_output
            columns
               patch_id number path 'patchID',
               patch_uid number path 'uniquePatchID',
               description varchar2(80) path 'patchDescription'
         ) x
     where x.description like 'Database Patch Set Update%';
  exit;" | sqlplus -s "sys/${password}@\"$SBDB\"" as sysdba > $PSU_LEVEL
;;
12)
  export DEST_PSU_LEVEL=`$ORACLE_BASE/product/$VERSION/db_1/OPatch/opatch lsinventory | grep -i 'Database Patch Set Update'| grep ${VERSION:0:15} |tr ')' '(' | cut -d'(' -f2`
  echo "set echo off ver off pages 0 trims on head off feed off
  with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
  select max(x.patch_id)
    from a,
         xmltable('InventoryInstance/patches/*'
            passing a.patch_output
            columns
               patch_id number path 'patchID',
               patch_uid number path 'uniquePatchID',
               description varchar2(80) path 'patchDescription'
         ) x
     where x.description like 'Database Patch Set Update%';
  exit;" | sqlplus -s "sys/${password}@\"$SBDB\"" as sysdba > $PSU_LEVEL
;;
*)
  export DEST_PSU_LEVEL=`$ORACLE_BASE/product/$VERSION/db_1/OPatch/opatch lsinventory | grep -i 'Database Release Update'| grep $VERSION |tr ')' '(' | cut -d'(' -f4`
  echo "set echo off ver off pages 0 trims on head off feed off
  with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
  select max(x.patch_id)
    from a,
         xmltable('InventoryInstance/patches/*'
            passing a.patch_output
            columns
               patch_id number path 'patchID',
               patch_uid number path 'uniquePatchID',
               description varchar2(80) path 'patchDescription'
         ) x
     where upper(x.description) like 'DATABASE RELEASE UPDATE%';
  exit;" | sqlplus -s "sys/${password}@\"$SBDB\"" as sysdba > $PSU_LEVEL
;;
esac


export PSU_LEVEL=$(tail -1 $PSU_LEVEL |sed -e 's/ //g')

if [ "$PSU_LEVEL" == "$DEST_PSU_LEVEL" ] ; then
  log_console "The Standard build database is at the requested PSU level, continuing with clone .........."
else
  log_console "The Standard build database is not at the requested PSU level"
  log_console "Request the database $ORACLE_SID be created at $PSU_LEVEL"
  log_console "Alternatively, you can create $ORACLE_SID at $PSU_LEVEL, then upgrade/downgrade to $VERSION using the patch_db.sh or rollback_patch_db.sh scripts"
  exit 1
fi
 

ORATAB=/etc/oratab
grep $ORACLE_SID $ORATAB >/dev/null | grep -v $ORACLE_SID[0-z] 2>&1
if [ $? -eq 0 ]; then
  log_console "Database already exists in ORATAB, drop/remove it before attempting clone"
  exit 1
else
  log_console "Adding ORATAB entry"
  echo $ORACLE_SID:${STD_DBMS_DIR}/app/oracle/product/$VERSION/db_1:N >> $ORATAB
fi 

#---------------------------------------------------------------------------
#  Check for sufficient free huge pages to accomodate source SGA
#---------------------------------------------------------------------------
export SGA_MAX_SIZE=2147483648

FREE_HUGE_PAGES=(`grep HugePages_Free /proc/meminfo | awk ' {print $2} '`)

if [ $(($FREE_HUGE_PAGES*2097152)) -lt $(($SGA_MAX_SIZE)) ]; then
   log_console "Free Huge Pages: $FREE_HUGE_PAGES"
   log_console "Free Huge Pages required to accmodate a $SGA_MAX_SIZE byte sga: $(($SGA_MAX_SIZE/2097152))"
   log_console "Insufficient Huge Pages allocated to accomodate the new database"
   exit 1
fi


#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

export ORAENV_ASK=NO
. oraenv >> $LOGFILE

export PATH=$ORACLE_HOME/bin:$PATH

#------------------------------------------------------------
#  Build/Start Database Instance
#------------------------------------------------------------

mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/rman
mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/sql

echo DB_NAME=$ORACLE_SID > $ORACLE_HOME/dbs/init_for_clone.pfile
echo SGA_TARGET=2G >>  $ORACLE_HOME/dbs/init_for_clone.pfile
$ORACLE_HOME/bin/orapwd file=$ORACLE_HOME/dbs/orapw${ORACLE_SID} password=${password} entries=10 


sqlplus -S  <<EOF  >>$LOGFILE
connect / as sysdba
whenever sqlerror exit failure 1
startup nomount pfile=?/dbs/init_for_clone.pfile
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Instance Startup Failed"
  exit 1
else
  log_console  "Instance Startup Successful"
fi

#------------------------------------------------------------
# Configure Listener 
#------------------------------------------------------------

export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`

if [ -z ${CONTEXT_NAME+x} ]; then 
  export TNS_ADMIN=$ORACLE_HOME/network/admin
else
  export TNS_ADMIN=$ORACLE_HOME/network/admin/$CONTEXT_NAME
  mkdir -p $TNS_ADMIN
  cp $ORACLE_HOME/network/admin/ldap.ora $TNS_ADMIN
  cp $ORACLE_HOME/network/admin/sqlnet.ora $TNS_ADMIN
fi

if [ -f $TNS_ADMIN/listener.ora ] ; then
  cp $TNS_ADMIN/listener.ora $TNS_ADMIN/listener.ora_bkup_$DATEVAR
fi

cat << label1 >> $TNS_ADMIN/listener.ora

${ORACLE_SID} =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = ${ORACLE_SID}_IPC))
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOSTNAME})(PORT = ${PORT}))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC${PORT}))
    )
  )

SECURE_REGISTER_${ORACLE_SID} = (IPC)

ADR_BASE_${ORACLE_SID} = ${STD_DBMS_DIR}/app/oracle

SID_LIST_${ORACLE_SID} =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${ORACLE_SID})
      (ORACLE_HOME = ${ORACLE_HOME})
      (SID_NAME = ${ORACLE_SID})
    )
  )


ENABLE_GLOBAL_DYNAMIC_ENDPOINT_${ORACLE_SID}=ON                # line added by Agent
VALID_NODE_CHECKING_REGISTRATION_${ORACLE_SID}=SUBNET          # line added by Agent

label1

#------------------------------------------------------------
# Configure TNS entry
#------------------------------------------------------------

if [ -f $TNS_ADMIN/tnsnames.ora ] ; then
  cp $TNS_ADMIN/tnsnames.ora $TNS_ADMIN/tnsnames.ora_bkup_$DATEVAR
fi

cat << label2 >> $TNS_ADMIN/tnsnames.ora

${ORACLE_SID}_${SERVER_NAME} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${HOSTNAME})(PORT = ${PORT}))
    )
    (CONNECT_DATA =
      (SID = ${ORACLE_SID})
    )
  )

label2

if [ "$MAJOR_REL" == "11" ] ; then
  srvctl add listener -l $ORACLE_SID -o $ORACLE_HOME -p "TCP:${PORT}/IPC:${ORACLE_SID}_IPC" >>$LOGFILE 
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> srvctl add listener failed!!!"
    exit 1
  fi
else
  srvctl add listener -l $ORACLE_SID -oraclehome $ORACLE_HOME -endpoints "TCP:${PORT}/IPC:${ORACLE_SID}_IPC" >>$LOGFILE 
  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> srvctl add listener failed!!!"
    exit 1
  fi
fi

srvctl setenv listener -l $ORACLE_SID -env "TNS_ADMIN=$TNS_ADMIN"
srvctl start listener -l $ORACLE_SID 
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> srvctl start listener failed!!!"
  exit 1
fi

mkdir -p ${STD_ADMP_DIR}/${ORACLE_SID}/adump

cat << label3 > $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_sb_db.cmd
run
{
ALLOCATE CHANNEL d1 TYPE DISK ;
ALLOCATE CHANNEL d2 TYPE DISK ;
ALLOCATE AUXILIARY CHANNEL a1 TYPE DISK ;
ALLOCATE AUXILIARY CHANNEL a2 TYPE DISK ;

duplicate target database to '${ORACLE_SID}'
from active database
logfile
GROUP 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M,
GROUP 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M

spfile
set db_unique_name='${ORACLE_SID}_${SERVER_NAME}'
set control_files='${STD_REDO1_DG}','${STD_REDO2_DG}','${STD_DATA_DG}'
set log_archive_dest_1='location=${STD_FRA_DG}'
set db_create_online_log_dest_1='${STD_REDO1_DG}'
set db_create_online_log_dest_2='${STD_REDO2_DG}'
set db_create_file_dest='${STD_DATA_DG}'
set db_recovery_file_dest='${STD_FRA_DG}'
set db_file_name_convert '+DATA_01','${STD_DATA_DG}'
set log_file_name_convert '+REDOA_01','${STD_REDO1_DG}','+REDOB_01','${STD_REDO2_DG}'
set db_file_name_convert '+DATA_01','${STD_DATA_DG}'
set local_listener='(DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=${ORACLE_SID}_IPC)))'
set audit_file_dest='${STD_ADMP_DIR}/${ORACLE_SID}/adump'
set job_queue_processes='0'
label3
if [ "$MAJOR_REL" > "12" ] ; then
  echo set \"_disk_sector_size_override\"=\'true\' >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_sb_db.cmd
fi
echo 'nofilenamecheck;' >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_sb_db.cmd
echo } >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_sb_db.cmd


rman_loc=$ORACLE_BASE/admin/$ORACLE_SID/rman
rman_job=duplicate_sb_db
NOW=`/bin/date '+%m-%d-%Y-%H%M%S'`
rman_cmdfile=${rman_loc}/${rman_job}.cmd
rman_logfile=${rman_loc}/${rman_job}_${NOW}.log
rman_outfile=$LOGFILE
rman_msgfile=$LOGFILE
debug_logfile=${rman_loc}/${rman_job}_${NOW}.log
#SOURCE=SB`echo $VERSION | tr -d . | cut -c1-5`
SOURCE=$SBDB
#DEST=$ORACLE_SID
export DEST=`echo '"'"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${SERVER_NAME})(PORT=${PORT}))(CONNECT_DATA=(SID=${ORACLE_SID})))"'"'`

log_console "Starting RMAN clone, this will take a few minutes please wait....."
log_console " "

########################################################################################
echo "Begin RMAN Job : " `/bin/date`                           >> $rman_outfile
echo -e "\n===========================================\n"      >> $rman_outfile
echodo rman target sys/${password}@$SOURCE \
auxiliary sys/${password}@${DEST} \
cmdfile=${rman_cmdfile} log=${rman_logfile}                    >> $rman_outfile 2>> $rman_outfile
echo -e "\n===========================================\n"      >> $rman_outfile
echo "End   RMAN Job : " `/bin/date`                           >> $rman_outfile
echo -e "\n\n\n\n"                                             >> $rman_outfile
########################################################################################

cat ${rman_logfile} | grep 'Finished Duplicate Db' >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo Including rman duplicate log..... >> $LOGFILE
  cat ${rman_logfile} >> $LOGFILE
  echo ========== End of rman duplicate log =========== >> $LOGFILE
  log_console "RMAN Duplicate Successful, continuing with clone"
else
  echo Including rman duplicate log..... >> $LOGFILE
  cat ${rman_logfile} >> $LOGFILE
  echo ========== End of rman duplicate log ============ >> $LOGFILE
  log_console "RMAN Duplicate Failed!!!"
  log_console "Attempting to drop database $ORACLE_SID......"
  dbca -silent -deleteDatabase -sourceDB $ORACLE_SID -sysPassword ${password} | tee -a $LOGFILE
  log_console "Drop of database $ORACLE_SID complete"
  log_console "Removing listener $ORACLE_SID"
  srvctl stop listener -l $ORACLE_SID | tee -a $LOGFILE
  srvctl remove listener -l $ORACLE_SID | tee -a $LOGFILE
  log_console "Listener $ORACLE_SID has been removed"
  log_console "Restoring network configuration files"
  if [ -f $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR ] ; then
    cp $ORACLE_HOME/network/admin/tnsnames.ora_bkup_$DATEVAR $ORACLE_HOME/network/admin/tnsnames.ora
  else
    rm $ORACLE_HOME/network/admin/tnsnames.ora
  fi
  if [ -f $ORACLE_HOME/network/admin/listener.ora_bkup_$DATEVAR ] ; then
    cp $ORACLE_HOME/network/admin/listener.ora_bkup_$DATEVAR $ORACLE_HOME/network/admin/listener.ora
  else
    rm $ORACLE_HOME/network/admin/listener.ora
  fi
  log_console "Network configuration files have been restored"
  log_console "Before re-attempting the clone to $ORACLE_SID, perform the following actions:"
  log_console "    1. Ensure database $ORACLE_SID has been dropped"
  log_console "    2. Ensure listener  $ORACLE_SID has been dropped"
  log_console "    3. Ensure network configuration files have been restored"    
  log_console " "
  exit 1
fi

#-----------------------------------------------------------
# Create redo logs with 4k block size
#-----------------------------------------------------------
log_console " "
log_console "Re-creating REDO log groups with 4k block size.............."
echo "shutdown immediate;" | sqlplus / as sysdba >> $LOGFILE
echo "startup;" | sqlplus / as sysdba >> $LOGFILE
echo "alter database add logfile group 3 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE

export CURRENT_DG=${LOGDIR}/CURRENT_DG_$ORACLE_SID.log
echo "set echo off ver off pages 0 trims on head off feed off
select group# from v\$log where status='CURRENT';
exit;" |  sqlplus -s / as sysdba > $CURRENT_DG

export CURRENT_DG=$(tail -1 $CURRENT_DG |sed 's/\s*$//g' | tr -d " ")

if [ "${CURRENT_DG}" -eq "1" ]; then
  echo "alter database drop logfile group 2;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter system switch logfile;" | sqlplus / as sysdba  >> $LOGFILE
  echo "shutdown immediate;" | sqlplus / as sysdba  >> $LOGFILE
  echo "startup;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database drop logfile group 1;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
elif [ "${CURRENT_DG}" -eq "2"]; then
  echo "alter database drop logfile group 1;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 1 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter system switch logfile;" | sqlplus / as sysdba >> $LOGFILE
  echo "shutdown immediate;" | sqlplus / as sysdba >> $LOGFILE
  echo "startup;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database drop logfile group 2;" | sqlplus / as sysdba >> $LOGFILE
  echo "alter database add logfile group 2 ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE 100M blocksize 4096;" | sqlplus / as sysdba >> $LOGFILE
else
  log_console "Invalid Current log group returned"
fi

#for ((i=4;i<=OG_COUNT;i++));
#  do
#    echo "GROUP ${i} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M," >> $ORACLE_BASE/admin/$ORACLE_SID/rman/duplicate_${SOURCE_DB}.cmd
#    echo "alter database add logfile group ${i} ('${STD_REDO1_DG}','${STD_REDO2_DG}') SIZE ${LOG_SIZE}M blocksize 4096;" | sqlplus / as sysdba
#  done

log_console "REDO log re-creation complete"
log_console "RDOO log configuration is as follows:"

echo "select group#, bytes, blocksize from v\$log;" | sqlplus -s / as sysdba | tee -a $LOGFILE


#------------------------------------------------------------
# Alter Character Set
#------------------------------------------------------------
cat << label4 > $ORACLE_BASE/admin/$ORACLE_SID/sql/alter_${ORACLE_SID}_character_sets.sql

spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/alter_character_sets.out
set echo on
set linesize 360
shutdown immediate;
startup restrict;
alter database character set INTERNAL_CONVERT $CHAR_SET;
alter database national character set INTERNAL_CONVERT $NCHAR_SET;
alter system disable restricted session;
alter system set job_queue_processes=40;
prompt ---------------------------------;
prompt NLS Parameters after conversion;
prompt ---------------------------------;
col parameter form a32
col value form a32
select * from v\$nls_parameters;
spool off
exit;

label4

cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/alter_${ORACLE_SID}_character_sets.sql > $ORACLE_PATH/runthis.sql

log_console " "
log_console "Start character set conversion on $ORACLE_SID"

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Character set convestion failed in sqlplus"
  exit 1
else
  log_console  "Character set conversion successful"
fi

rm $ORACLE_PATH/runthis.sql

#------------------------------------------------------------
# Correct Issue with sys.KU$_RADM_FPTM_VIEW if nls character  
# set is UTF8 as described in Oracle DOC ID 1641033.1
#------------------------------------------------------------
if [ $NCHAR_SET == 'UTF8' ] ; then

  log_console "Correcting KU\$_RADM_FPTM_VIEW issue with UTF8 nls character set"

  cat << label5 > $ORACLE_BASE/admin/$ORACLE_SID/sql/alter_${ORACLE_SID}_ku_type.sql

spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/alter_ku_type.out
set echo on
set linesize 360
alter type ku\$_radm_fptm_t compile reuse settings;
@?/rdbms/admin/utlrp.sql;
spool off
exit;

label5

  cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/alter_${ORACLE_SID}_ku_type.sql > $ORACLE_PATH/runthis.sql


sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF

  if [ $? -gt 0 ] ; then
    log_console "ERROR ---> alter type failed in sqlplus"
    exit 1
  else
    log_console  "alter type ku\$_radm_fptm_t successful"
    log_console " "
  fi

  rm $ORACLE_PATH/runthis.sql

fi


#------------------------------------------------------------
# Add database to HAS
#------------------------------------------------------------

if [ "$MAJOR_REL" == "11" ] ; then
  srvctl add database -d ${ORACLE_SID}_${SERVER_NAME} -o ${ORACLE_HOME} -p ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora -i ${ORACLE_SID} -a "${STD_DATA_DG#?},${STD_REDO1_DG#?},${STD_REDO2_DG#?}" | tee -a $LOGFILE
  srvctl start database -d ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
else
  srvctl add database -db ${ORACLE_SID}_${SERVER_NAME} -oraclehome ${ORACLE_HOME} -spfile ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora -instance ${ORACLE_SID} -diskgroup "${STD_DATA_DG#?},${STD_REDO1_DG#?},${STD_REDO2_DG#?}" | tee -a $LOGFILE
  srvctl start database -db ${ORACLE_SID}_${SERVER_NAME} | tee -a $LOGFILE
fi


#------------------------------------------------------------
# Create symbolic link from $ORACLE_BASE/admin/$ORACLE_SID
# to $ORACLE_HOME to suuport Gardium and the viloin agent
#------------------------------------------------------------

log_console " "
if [ -e $ORACLE_BASE/admin/$ORACLE_SID/oracle_home ] ; then
   log_console "The oracle home link already exists, recreating the link"
   rm  $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link" 
   else
     log_console "Oracle Home symbolic link has been re-created"
   fi
else
   ln -s $ORACLE_HOME $ORACLE_BASE/admin/$ORACLE_SID/oracle_home 
   if [ $? -gt 0 ] ; then
     log_console "Oracle Home symbolic link create failed"
     log_console "Please resolve issue and create the link" 
   else
     log_console "Oracle Home symbolic link has been created"
   fi
fi

#------------------------------------------------------------
# Create Application Service and Service Trigger
#------------------------------------------------------------


cat << label5 > $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql

spool ${ORACLE_BASE}/admin/${ORACLE_SID}/sql/create_service.out
exec dbms_service.create_service( -
        SERVICE_NAME => '${ORACLE_SID}_APP', -
        NETWORK_NAME => '${ORACLE_SID}_APP', -
        FAILOVER_METHOD => 'BASIC', -
        FAILOVER_TYPE => 'SELECT', -
        FAILOVER_RETRIES => 180, -
        FAILOVER_DELAY => 1);

exec dbms_service.start_service('${ORACLE_SID}_APP', '${ORACLE_SID}');
exec dbms_service.delete_service('${SOURCE}_xoragdbw2d');

CREATE OR REPLACE TRIGGER StartDgServices after startup on database
DECLARE
  db_role VARCHAR(30);
  db_open_mode VARCHAR(30);
BEGIN

  execute immediate ' ALTER SYSTEM SET SERVICE_NAMES='' '' ';

  SELECT DATABASE_ROLE, OPEN_MODE INTO db_role, db_open_mode FROM V\$DATABASE;

  IF db_role = 'PRIMARY'
        THEN DBMS_SERVICE.START_SERVICE('${ORACLE_SID}_APP');
  END IF;
  --IF db_role = 'PHYSICAL STANDBY' AND db_open_mode LIKE 'READ ONLY%'
  --      THEN DBMS_SERVICE.START_SERVICE('${ORACLE_SID}_RPT');
  --END IF;
END;
/

spool off;
exit;


label5


cat  $ORACLE_BASE/admin/$ORACLE_SID/sql/create_${ORACLE_SID}_app_service.sql > $ORACLE_PATH/runthis.sql

echo Start create service on $ORACLE_SID

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@runthis.sql
EOF
if [ $? -gt 0 ] ; then
  log_console "ERROR ---> Create application service and trigger failed in sqlplus"
  exit 1
else
  log_console  "Create application service and trigger successful"
fi

rm $ORACLE_PATH/runthis.sql

#-------------------------------------------------------------
# Remove Audit Trail timestamps for old dbids
#-------------------------------------------------------------
export DB_ID_LIST=$LOGDIR/db_id_list_$PRIMARY_DB.log
echo "set echo off ver off pages 0 trims on head off feed off
select unique database_id from DBA_AUDIT_MGMT_LAST_ARCH_TS minus select dbid from v\$database;
exit;" | sqlplus -s /  as sysdba > $DB_ID_LIST

export DB_ID_LIST=$(tail -1 $DB_ID_LIST |sed -e 's/ //g')
log_console " "
log_console "List Of Audit Trail timestamp DB_IDs to delete: $DB_ID_LIST"

for DBID in $DB_ID_LIST
  do
    log_console "Removing audit trail timestamps for $DBID"
    sqlplus -S / as sysdba <<EOF >> $LOGFILE
    whenever sqlerror exit failure 1
    exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,DATABASE_ID=>$DBID); 
    exec DBMS_AUDIT_MGMT.CLEAR_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE =>DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,DATABASE_ID=>$DBID);
    exit;
EOF
    if [ $? -gt 0 ] ; then
      log_console "Error -----> Removal of audit trail timestamp for $DBID failed"
    else
      log_console "Removal of audit trail timestamps for $DBID successful"
    fi
  done

#-------------------------------------------------------------
# Remove AWR data for old DBIDs and set 30 retention
#-------------------------------------------------------------
log_console " "
log_console "Removing old AWR DBIDs and set snap shot retention to 30 days"

sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
@remove_old_awr_dbids.sql
EXECUTE DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(retention => 43200);
exit;
EOF
    
if [ $? -gt 0 ] ; then
   log_console "Error -----> AWR updates failed"
else
   log_console "AWR updates successful"
fi


#-------------------------------------------------------------
# Enable Block Change Tracking
#-------------------------------------------------------------
log_console " "
log_console "Enabling Block Change Tracking"
sqlplus -S / as sysdba <<EOF >> $LOGFILE
whenever sqlerror exit failure 1
set linesize 160
col STATUS format a12
col FILENAME format a80
ALTER DATABASE ENABLE BLOCK CHANGE TRACKING;
SELECT status, filename FROM V\$BLOCK_CHANGE_TRACKING; 
exit;
EOF
if [ $? -gt 0 ] ; then
  log_console "Error -----> Enable Block Change Tracking failed"
else
  log_console "Block Change Tracking has been enabled"
fi


#----------------------------------------------------------
#  Add database to OEM
#----------------------------------------------------------
log_console " "
log_console "Starting OEM update........."

if [ -x $ORACLE_BASE/product/emcli/emcli ] ; then
  log_console " emcli exists and is executable, updating OEM"
  $ORACLE_BASE/product/emcli/emcli add_target -name="${ORACLE_SID}_${SERVER_NAME}" -type="oracle_database" -host="$HOSTNAME" -credentials="UserName:dbsnmp;password:drugs2gogo;Role:normal" -properties="SID:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};MachineName:$HOSTNAME" -groups="Unassigned:composite"
  if [ $? -gt 0 ] ; then
    log_console "OEM Database Target add has failed!!!  Please add database to OEM manually"
  else
    log_console "OEM  Database Target has been added"
    $ORACLE_BASE/product/emcli/emcli set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Comment:Standard Build" 
    $ORACLE_BASE/product/emcli/emcli set_target_property_value -property_records="${ORACLE_SID}_${SERVER_NAME}:oracle_database:Contact:(Oracle DBA)" 
    schedule_purge
  fi
  $ORACLE_BASE/product/emcli/emcli add_target -name="${ORACLE_SID}_${HOSTNAME}" -type="oracle_listener" -host="$HOSTNAME"  -properties="LsnrName:${ORACLE_SID};Port:${PORT};OracleHome:${ORACLE_HOME};ListenerOraDir:${TNS_ADMIN};Machine:$HOSTNAME" -groups="Unassigned:composite"
  if [ $? -gt 0 ] ; then
    log_console "OEM Listener Target add has failed!!!  Please update OEM with the new listener manually"
  else
    log_console "OEM Listener  Target has been added"
    $ORACLE_BASE/product/emcli/emcli set_target_property_value -property_records="${ORACLE_SID}_${HOSTNAME}:oracle_listener:Contact:(Oracle DBA)" 
  fi
else
  log_console "emcli is not installed on this server, please add database to OEM manually"
fi

#----------------------------------------------------------
#  Create recovery catalog and register database
#----------------------------------------------------------
create_rcat.sh $ORACLE_SID | tee -a $LOGFILE



log_console " "
log_console "Create clone of SB to  $2 complete  `uname -svrn` at `date` using $0 "
echo 


exit 0

