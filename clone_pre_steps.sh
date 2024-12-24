#!/bin/bash

###################################################################################
# Script Name :    clone_pre_steps.sh                                             #
#                                                                                 #
# Purpose     :    To be run prior to a clone refresh                             #
#                                                                                 #
# Step        :    (1) Create DataBase Restore Point                              #
#             :    (2) Run Archivelog Backup                                      #
#             :    (3) Extract Service ID's                                       #
#             :    (4) Extract User ID's                                          #
#             :    (5) Extract DataPump Directory Object                          #
#             :    (6) Create DataPump Parameter Files                            #
#             :    (7) Export Service ID's                                        #
#             :    (8) Export User ID's                                           #
#             :    (9) Export Strong Users                                        #
#             :   (10) Extract RMAN Configuration Settings                        #
#             :   (11) Generate Create User ID Statements (precaution)            #
#             :   (12) Generate Create Role Statements (precaution)               #
#             :   (13) Generate SGA and PGA Alter Statements                      #
#             :   (14) Create SQL Profile Staging Table (if sql_profiles found)   #
#             :   (15) Export SQL Profiles (if sql_profiles found)                #
#             :   (16) Create SQL Baseline Staging Table (if sql_baselines found) #
#             :   (17) Export SQL Baselines (if sql_baselines found)              #
#             :   (18) Generate Lock User Statements in support of DGB            #
#             :   (19) Preserve Schema Owner and HE_CUSTOM Passwords              #
# Required    :                                                                   #
# Parameters  :  Script Prompts For Input Parameters                              #
#                                                                                 #
# Initial Date:  02/01/2018                                                       #
###################################################################################

clear

echo "Enter DataBase Name To Be Cloned"
read DBName

# Confirm DataBase Name Entered
if [ -z "${DBName}" ]; then
   echo
   echo "Must Enter DataBase Name"
   exit 1
fi

# Upper Case DataBase Name
DBName=`echo $DBName |tr "[:lower:]" "[:upper:]"`

# Prod Cannot Be the Database Being Refreshed
if [ ${DBName} = "HEPYPRD" ] ; then
   echo "Prod Database ${DBName} Cannot Be the DataBase To Be Refreshed"
   exit 1
fi

# Confirm Valid Database Name
case ${DBName} in
 "HEPYDEV"|"HEPYDEV2"|"HEPYDEV3"|"HEPYCFG"|"HEPYQA"|"HEPYQA2"|"HEPYQA3"|"HEPYSTS"|"HEPYUAT"|"HEPYMGR2"|"HEPYPRD")
     ;;
     *)
     echo
     echo "${DBName} Not A Recognized PAYOR DataBase - Script Aborting"
     echo
     exit 1
     ;;      
esac

echo "Enter Target(Source) DataBase"
read TARGETDB

# Confirm Target DataBase Entered
if [ -z "${TARGETDB}" ]; then
   echo
   echo "Must Enter Target DataBase"
   exit 1
fi

# Upper Case Target DataBase
TARGETDB=`echo $TARGETDB |tr "[:lower:]" "[:upper:]"`

# Confirm Valid Target Database Name
case ${TARGETDB} in
 "HEPYMASK"|"HEPYDEV"|"HEPYDEV2"|"HEPYDEV3"|"HEPYCFG"|"HEPYQA"|"HEPYQA2"|"HEPYQA3"|"HEPYSTS"|"HEPYUAT"|"HEPYMGR2"|"HEPYPRD")
     ;;
     *)
     echo
     echo "${TARGETDB} Not A Recognized PAYOR DataBase - Script Aborting"
     echo
     exit 1
     ;;      
esac

# Confirm Aux and Target Not The Same
if [ ${DBName} = ${TARGETDB} ] ; then
     echo
     echo "DataBase to be cloned and Target Database cannot be the same - Script Aborting"
     echo
     exit 1
fi

echo "Enter Schema Owner (e.g. PROD)"
read SCHema

# Confirm Schema Owner Entered
if [ -z "${SCHema}" ]; then
   echo
   echo "Must Enter Schema Owner"
   exit 1
fi

# Upper Case Schema
SCHema=`echo $SCHema |tr "[:lower:]" "[:upper:]"`

echo "Enter DBA ID"
read DBAID

# Confirm DBA ID Entered
if [ -z "${DBAID}" ]; then
   echo
   echo "Must Enter DBA ID"
   exit 1
fi

# Upper Case DBA ID
DBAID=`echo $DBAID |tr "[:lower:]" "[:upper:]"`

echo "Enter DBA Password"
read -s DBAPASS

# Confirm DBA Password Entered
if [ -z "${DBAPASS}" ]; then
   echo
   echo "Must Enter DBA Password"
   exit 1
fi

echo "Enter Script Starting Step Number"
read STEPRST

# Confirm Starting Step Number Entered
if [ -z "${STEPRST}" ]; then
   echo
   echo "Must Enter Script Starting Step Number"
   exit 1
fi

# Check For Numeric Value For Start Step
if ! expr "${STEPRST}" : "[0-9]*$" > /dev/null ; then
   echo
   echo 'Script Starting Step Number Must Be Numeric'
   exit 1
fi

# Check For Valid Restart Step
if [ $STEPRST -lt 1 ] || [ $STEPRST -gt 23 ]; then
   echo
   echo "Restart Step Must Be Between 1-23"
   exit 1
fi

# Set Refresh Date
RD="`date +%b_%d_%Y`"

# If Restart Confirm Directory Exists (May Be a Different Day)
if [ $STEPRST -gt 1 ]; then
 if [ ! -d /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} ] ; then
    echo
    echo "Directory /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} Not Found - Script Aborting"
    exit 1   
 fi
fi

# Set Script Name
SCRIPT_NAME=`basename $0`

# Set RMAN Catalog
export RCATDB=RCATDEV

# Make Directory 
if [ ! -d /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} ] ; then
   mkdir -p /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD}
   chmod 700 /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD}
fi

# Make Datapump Output Directory (if not exists)
if [ ! -d /oraexport/u01/datapump ] ; then
   mkdir -p /oraexport/u01/datapump
fi

# Change To Output Directory
cd /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD}

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > oraenv_refresh_${DBName}.out 2>&1

shopt -s expand_aliases

# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Declare Work Variables
typeset -i BASELINECNT=0
typeset -i PROFILECNT=0
typeset -i RC=0
typeset -i ROLECNT=0
typeset -i SQLRC=0

# Set DateTime
DATE=`date +%m:%d:%y_%H:%M:%S`

# Set Restore Point Name
RESTORE_POINT="BEFORE_REFRESH_${RD}"

# Define Strong Users Parameter Files
EXPPARFILE=export_strong_users_table_${RD}.par
IMPPARFILE=import_strong_users_table_${RD}.par

# Set Log File
LOGOUT="${DBName}_refresh_preclone_${DATE}.log"

# Set Mail Distribution
MAILIDS=bermane@aetna.com

# Confirm DBA Password In DataBase To Be Cloned
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect ${DBAID}/${DBAPASS}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Connecting To ${DBName} Using Input DBA Password"
   exit 1
fi

# Confirm DBA Password In Target DataBase
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect ${DBAID}/${DBAPASS}@${TARGETDB}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Connecting To Target DataBase ${TARGETDB} Using Input DBA Password"
   exit 1
fi

# Set RMAN Catalog Password
#export RCATPASS=`ssh -a -o StrictHostKeyChecking=no -i ~oracle/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com retrieve --AccountName rcat_${RCATDB}_${DBName} --SystemName NMA_Oracle --ReasonText "RMAN Operation" | cut -f2 | tr -d '[[:space:]]'`

# Redirect standard output and standard error
exec > >(tee ${LOGOUT}) 2>&1

# Note Script Start Time
echo
echo "Script ${SCRIPT_NAME} Starting at "`date '+%Y-%m-%d %H:%M:%S'`
echo
echo "Database ${DBName} being refreshed from ${TARGETDB} "
echo
#********************************* Step #1 *********************************#
STEPNO=1
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 1 - Creating Restore Point at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set echo on trimspool on line 140 feed off
 col name format a30
 col scn format 99999999999999999999
 col time format a35
 update aedba.rman_heartbeat set timestmp=sysdate where dbname = '${DBName}';
 commit;
 create restore point "${RESTORE_POINT}";
 select name, scn, time from v\$restore_point order by time;
 select dbname, to_char(timestmp, 'YYYY-MM-DD HH:MI:SS') as "Heartbeat Timestamp"
 from aedba.rman_heartbeat
 where dbname = '${DBName}';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating Restore Point"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #2 *********************************#
STEPNO=2
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 2 - Running Archivelog Backup at "`date '+%Y-%m-%d %H:%M:%S'`

# Set Backup Time
BT=`date +%m%d%y%H%M%S`

rman << EOF
connect target /
connect catalog ${DBName}/${RCATPASS}@${RCATDB}
set echo on
backup device type sbt tag 'BK_${DBName}_ARC_${BT}' archivelog all not backed up delete all input;
EOF

# Obtain RMAN Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Running Archivelog Backup"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #3 *********************************#
STEPNO=3
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 3 - Extracting Service ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/find_s_for_export.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Extracting Service ID's"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #4 *********************************#
STEPNO=4
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 4 - Extracting User ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/find_users_for_export.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Extracting User ID's"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #5 *********************************#
STEPNO=5
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 5 - Extracting Directory Object at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_replace_directory.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Extracting Directory Object"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #6 *********************************#
STEPNO=6
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 6 - Creating DataPump Parameter Files at "`date '+%Y-%m-%d %H:%M:%S'`

# Service ID Export
echo "schemas=" > tmp.par
cat export_S.par >> tmp.par
sed -e '$s/,//' tmp.par > tmp2.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp2.par
echo "REUSE_DUMPFILES=Y" >> tmp2.par
echo "DUMPFILE=EXPORT_S_FROM_${DBName}_${RD}.dmp" >> tmp2.par
echo "LOGFILE=EXPORT_S_FROM_${DBName}_${RD}.log" >> tmp2.par
mv tmp2.par export_S_${RD}.par

# Service ID Import
echo "schemas=" > tmp.par
cat export_S.par >> tmp.par
sed -e '$s/,//' tmp.par > tmp2.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp2.par
echo "DUMPFILE=EXPORT_S_FROM_${DBName}_${RD}.dmp" >> tmp2.par
echo "LOGFILE=IMPORT_S_FROM_${DBName}_${RD}.log" >> tmp2.par
mv tmp2.par import_S_${RD}.par

# User ID Export
echo "schemas=" > tmp.par
cat export_current_USERS.par >> tmp.par
sed -e '$s/,//' tmp.par > tmp2.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp2.par
echo "REUSE_DUMPFILES=Y" >> tmp2.par
echo "DUMPFILE=EXPORT_USERS_FROM_${DBName}_${RD}.dmp" >> tmp2.par
echo "LOGFILE=EXPORT_USERS_FROM_${DBName}_${RD}.log" >> tmp2.par
mv tmp2.par export_current_USERS_${RD}.par

# User ID Import
echo "schemas=" > tmp.par
cat export_current_USERS.par |grep -v ${DBAID} >> tmp.par
sed -e '$s/,//' tmp.par > tmp2.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp2.par
echo "DUMPFILE=EXPORT_USERS_FROM_${DBName}_${RD}.dmp" >> tmp2.par
echo "LOGFILE=IMPORT_USERS_FROM_${DBName}_${RD}.log" >> tmp2.par
#echo 'EXCLUDE=SCHEMA:"IN ('"'${DBAID}')"'"' >> tmp2.par
mv tmp2.par import_current_USERS_${RD}.par

# DBA ID Import
echo "schemas=${DBAID}" > tmp.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp.par
echo "DUMPFILE=EXPORT_USERS_FROM_${DBName}_${RD}.dmp" >> tmp.par
echo "LOGFILE=IMPORT_DBAID_FROM_${DBName}_${RD}.log" >> tmp.par
mv tmp.par import_${DBAID}_${RD}.par

# Strong Users Export
echo "COMPRESSION=NONE" > ${EXPPARFILE}
echo "DIRECTORY=DATA_PUMP_DIR" >> ${EXPPARFILE}
echo "REUSE_DUMPFILES=Y" >> ${EXPPARFILE}
echo "DUMPFILE=EXPORT_STRONG_USERS_FROM_${DBName}_${RD}.dmp" >> ${EXPPARFILE}
echo "LOGFILE=EXPORT_STRONG_USERS_FROM_${DBName}_${RD}.log" >> ${EXPPARFILE}
echo "TABLES=AEDBA.STRONG_USERS" >> ${EXPPARFILE}

# Strong Users Import
echo "DIRECTORY=DATA_PUMP_DIR" > ${IMPPARFILE}
echo "DUMPFILE=EXPORT_STRONG_USERS_FROM_${DBName}_${RD}.dmp" >> ${IMPPARFILE}
echo "LOGFILE=IMPORT_STRONG_USERS_FROM_${DBName}_${RD}.log" >> ${IMPPARFILE}
echo "TABLES=AEDBA.STRONG_USERS" >> ${IMPPARFILE}
echo "REMAP_SCHEMA=AEDBA:AEDBA" >> ${IMPPARFILE}
echo "TABLE_EXISTS_ACTION=TRUNCATE" >> ${IMPPARFILE}

# SQL Profiles Export
echo "COMPRESSION=NONE" > tmp.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp.par
echo "REUSE_DUMPFILES=Y" >> tmp.par
echo "DUMPFILE=EXPORT_SQL_PROFILES_FROM_${DBName}_${RD}.dmp" >> tmp.par
echo "LOGFILE=EXPORT_SQL_PROFILES_FROM_${DBName}_${RD}.log" >> tmp.par
echo "TABLES=${DBAID}.PROFILE_STGTAB" >> tmp.par
mv tmp.par export_SQL_Profiles_${RD}.par

# SQL Profiles Import
echo "DIRECTORY=DATA_PUMP_DIR" > tmp.par
echo "DUMPFILE=EXPORT_SQL_PROFILES_FROM_${DBName}_${RD}.dmp" >> tmp.par
echo "LOGFILE=IMPORT_SQL_PROFILES_FROM_${DBName}_${RD}.log" >> tmp.par
echo "TABLES=${DBAID}.PROFILE_STGTAB" >> tmp.par
echo "REMAP_SCHEMA=${DBAID}:${DBAID}" >> tmp.par
echo "TABLE_EXISTS_ACTION=TRUNCATE" >> tmp.par
mv tmp.par import_SQL_Profiles_${RD}.par

# SQL Baselines Export
echo "COMPRESSION=NONE" > tmp.par
echo "DIRECTORY=DATA_PUMP_DIR" >> tmp.par
echo "REUSE_DUMPFILES=Y" >> tmp.par
echo "DUMPFILE=EXPORT_SQL_BASELINES_FROM_${DBName}_${RD}.dmp" >> tmp.par
echo "LOGFILE=EXPORT_SQL_BASELINES_FROM_${DBName}_${RD}.log" >> tmp.par
echo "TABLES=${DBAID}.BASELINE_STGTAB" >> tmp.par
mv tmp.par export_SQL_Baselines_${RD}.par

# SQL Baselines Import
echo "DIRECTORY=DATA_PUMP_DIR" > tmp.par
echo "DUMPFILE=EXPORT_SQL_BASELINES_FROM_${DBName}_${RD}.dmp" >> tmp.par
echo "LOGFILE=IMPORT_SQL_BASELINES_FROM_${DBName}_${RD}.log" >> tmp.par
echo "TABLES=${DBAID}.BASELINE_STGTAB" >> tmp.par
echo "REMAP_SCHEMA=${DBAID}:${DBAID}" >> tmp.par
echo "TABLE_EXISTS_ACTION=TRUNCATE" >> tmp.par
mv tmp.par import_SQL_Baselines_${RD}.par

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #7 *********************************#
STEPNO=7
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 7 - Exporting Service ID's at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Export
expdp parfile=export_S_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Export Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Exporting Service ID's"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #8 *********************************#
STEPNO=8
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 8 - Exporting User ID's at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Export
expdp parfile=export_current_USERS_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Export Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Exporting User ID's"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #9 *********************************#
STEPNO=9
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 9 - Exporting Strong Users at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Export
expdp parfile=export_strong_users_table_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Export Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Exporting Strong Users"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #10 *********************************#
STEPNO=10
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 10 - Extracting RMAN Configuration Settings at "`date '+%Y-%m-%d %H:%M:%S'`

rman << EOF
connect target /
connect catalog ${DBName}/${RCATPASS}@${RCATDB}
spool log to 'show_all.out';
show all;
spool log off;
EOF

# Obtain RMAN Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Extracting RMAN Configuration Parameters"
   exit 1
fi

cat show_all.out|egrep -v "RMAN>|RMAN-|Recovery Manager|Spooling|# default|configuration parameters for|^$" > config.rman

echo
cat config.rman
echo

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #11 *********************************#
STEPNO=11
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 11 - Generate Create User ID Statements at "`date '+%Y-%m-%d %H:%M:%S'`

# Extract DataBase ID's
/oradb/app/oracle/local/scripts/refresh/${DBName}/user_privs.sh ${DBName} ${RD}

# Obtain Extract Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Generating Create User ID Statements"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #12 *********************************#
STEPNO=12
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 12 - Generate Create Role Statements at "`date '+%Y-%m-%d %H:%M:%S'`

# Extract Create Role Statements
/oradb/app/oracle/local/scripts/refresh/${DBName}/role_privs.sh ${DBName} ${RD}

# Obtain Extract Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Generating Create Role Statements"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi

#********************************* Step #13 *********************************#
STEPNO=13
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 13 - Extracting SGA and PGA Info at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_change_sga.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Extracting SGA and PGA Info"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #14 *********************************#
STEPNO=14
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 14 - Create SQL Profile Staging Table at "`date '+%Y-%m-%d %H:%M:%S'`

# Create SQL Profile Staging Table
sqlplus -s /nolog << EOF
 connect ${DBAID}/${DBAPASS}
 whenever sqlerror exit failure;
 set pagesize 0 head off feed off trimspool on
 spool sql_profile_count.out
 select trim(count(*))
 from dba_sql_profiles
 where status = 'ENABLED';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Obtaining Count of SQL Profiles"
   echo
   exit 1
fi

PROFILECNT=`cat sql_profile_count.out`
if [ ${PROFILECNT} -gt 0 ] ; then
   sqlplus -s /nolog << EOF
   connect ${DBAID}/${DBAPASS}
   DROP TABLE PROFILE_STGTAB;
   WHENEVER SQLERROR EXIT FAILURE;
   EXEC DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF (table_name  => 'PROFILE_STGTAB');
   EXEC DBMS_SQLTUNE.PACK_STGTAB_SQLPROF (profile_category => '%', staging_table_name => 'PROFILE_STGTAB');
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Creating SQL Profile Staging Table"
   exit 1
fi

else

  echo "No SQL Profiles Found in ${DBName}"
  SQLRC=0
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #15 *********************************#
STEPNO=15
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

if [ ! "${PROFILECNT}" ] ; then
 if [ $STEPRST -eq $STEPNO ] ; then
   echo "Step ${STEPNO} is not restartable, need to restart at previous step - Script Aborting"
   exit 1
 else
   echo "Step ${STEPNO} - Environment Variable PROFILECNT Not Defined - Script Aborting"
   exit 1
 fi
fi

if [ ${PROFILECNT} -gt 0 ] ; then
echo
echo "Step 19 - Exporting SQL Profiles at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Export
expdp parfile=export_SQL_Profiles_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Export Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Exporting SQL Profiles"
   exit 1
fi

else
  echo
  echo "STEP ${STEPNO} - No SQL Profiles To Export"
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #16 *********************************#
STEPNO=16
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 16 - Create SQL Plan Baseline Staging Table at "`date '+%Y-%m-%d %H:%M:%S'`

# Create SQL Plan Baseline Staging Table
sqlplus -s /nolog << EOF
 connect ${DBAID}/${DBAPASS}
 whenever sqlerror exit failure;
 set pagesize 0 head off feed off trimspool on
 spool sql_baseline_count.out
 select trim(count(*))
 from dba_sql_plan_baselines
 where enabled = 'YES'
 and accepted = 'YES';
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Obtaining Count of SQL Plan Baselines"
   echo
   exit 1
fi

BASELINECNT=`cat sql_baseline_count.out`
if [ ${BASELINECNT} -gt 0 ] ; then
    sqlplus -s /nolog << EOF
    connect ${DBAID}/${DBAPASS}
    var res number;
    DROP TABLE BASELINE_STGTAB;
    WHENEVER SQLERROR EXIT FAILURE;
    EXEC DBMS_SPM.CREATE_STGTAB_BASELINE(table_name =>'BASELINE_STGTAB');
    EXEC :res := DBMS_SPM.PACK_STGTAB_BASELINE(table_name => 'BASELINE_STGTAB',enabled => 'YES',accepted => 'YES');
    print :res
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Creating SQL Plan Baselines Staging Table"
   exit 1
fi

else
   echo "No SQL Plan Baselines Found in ${DBName}"
   SQLRC=0
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #17 *********************************#
STEPNO=17
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

if [ ! "${BASELINECNT}" ] ; then
 if [ $STEPRST -eq $STEPNO ] ; then
   echo "Step ${STEPNO} is not restartable, need to restart at previous step - Script Aborting"
   exit 1
 else
   echo "Step ${STEPNO} - Environment Variable BASELINECNT Not Defined - Script Aborting"
   exit 1
 fi
fi

if [ ${BASELINECNT} -gt 0 ] ; then
echo
echo "Step 17 - Exporting SQL Plan Baselines at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Export
expdp parfile=export_SQL_Baselines_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Export Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Exporting SQL Plan Baselines"
   exit 1
fi

else
  echo
  echo "STEP ${STEPNO} - No SQL Plan Baselines To Export"
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #18 *********************************#
STEPNO=18
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 18 - Creating Lock/Unlock Statements  at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_lock_user_accounts.sql ${DBName} ${RD}
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_unlock_user_accounts.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Generating Lock/Unlock Statements"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #19 *********************************#
STEPNO=19
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 19 - Preserving Schema Owner and HE_CUSTOM Passwords  at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_preserve_schema_pswd.sql ${DBName} ${RD} ${SCHema}
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_preserve_schema_pswd.sql ${DBName} ${RD} 'HE_CUSTOM'
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Preserving Schema Owner and HE_CUSTOM Passwords"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* End Steps *********************************#

# Change Permissions
chmod 600 *.sql *.out *.par *.log *.rman

echo
echo "Script ${SCRIPT_NAME} Ended at "`date '+%Y-%m-%d %H:%M:%S'`
echo

