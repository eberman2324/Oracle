#!/bin/bash

#############################################################################
# Script Name :    clone_post_steps.sh                                      #
#                                                                           #
# Purpose     :    To be run after a clone refresh                          #
#                                                                           #
#             :    (1) Lock AppD account and kill running sessions          #
#             :    (2) Create Drop User Statements For Target User ID's     #
#             :    (3) Drop Target User ID's                                #
#             :    (4) Create Drop User Statements For Target Service ID's  #
#             :    (5) Drop Target Service ID's                             #
#             :    (6) Set Directory Object Path                            #
#             :    (7) Create Preserved Unique Roles (if exist)             #
#             :    (8) Import User ID's                                     #
#             :    (9) Import Service ID's                                  #
#             :   (10) Import Strong Users                                  #
#             :   (11) Grant Directory Object Permissions                   #
#             :   (12) Disable Data Guard                                   #
#             :   (13) Configure RMAN                                       #
#             :   (14) Compile Invalids                                     #
#             :   (15) Resize SGA/PGA                                       #
#             :   (16) Shutdown DataBase                                    #
#             :   (17) Start DataBase                                       #
#             :   (18) Show SGA/PGA Sizes                                   #
#             :   (19) Truncate Flux_Cluster Table                          #
#             :   (20) Change SYS Password                                  #
#             :   (21) Change HEDBA Password                                #
#             :   (22) Lock Users not approved by DGB                       #
#             :   (23) Set AWR Snapshot Interval to 15 minutes              #
#             :   (24) Preserve Schema Owner and HE_CUSTOM Passwords        #
#             :   (25) Performance team grants	                            #
#             :   (26) UnLock appD                                          #
# Required    :                                                             #
# Parameters  :  Script Prompts For Input Parameters                        #
#                                                                           #
# Initial Date:  02/01/2018                                                 #
#############################################################################

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
     "HEPYDEV"|"HEPYDEV2"|"HEPYDEV3"|"HEPYCFG"|"HEPYQA"|"HEPYQA2"|"HEPYQA3"|"HEPYSTS"|"HEPYUAT"|"HEPYMGR2")
     ;;
     *)
     echo
     echo "${DBName} Not A Recognized PAYOR DataBase - Script Aborting"
     echo
     exit 1
     ;;
esac

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

echo "Enter Directory Where Clone Pre Run Scripts Reside (Format: Mon_DD_YYYY)"
read RD

# Confirm Directory Where Clone Pre Run Scripts Reside Entered
if [ -z "${RD}" ]; then
   echo
   echo "Must Enter Directory Where Clone Pre Run Scripts Reside"
   exit 1
fi

# Confirm Directory Exists
if [ ! -d /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} ] ; then
   echo
   echo "Directory /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} Not Found - Script Aborting"
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
if [ $STEPRST -lt 1 ] || [ $STEPRST -gt 26 ]; then
   echo
   echo "Restart Step Must Be Between 1-26"
   exit 1
fi

# Set Script Name
SCRIPT_NAME=`basename $0`

# Set RMAN Catalog
export RCATDB=RCATDEV

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
typeset -i RC=0
typeset -i SQLRC=0

# Set DateTime
DATE=`date +%m:%d:%y_%H:%M:%S`

# Set Log File
LOGOUT="${DBName}_refresh_postclone_${DATE}.log"

# Set Mail Distribution
MAILIDS=bermane@aetna.com

# Set Host Name
HOST=`hostname -s`

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

# Check For User Connections
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
set pagesize 0 head off feed off trimspool on
spool user_count.out
select trim(count(*))
from v\$session
where regexp_like(username, '[ANS][0-9]{6}.*');
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered Checking For User Connections"
   exit 1
else
   USERCNT=`cat user_count.out`
   if [ ${USERCNT} -gt 0 ] ; then
      echo "There Are Currently ${USERCNT} Connections To DataBase ${DBName} - Script Aborting"
      #exit 1
   fi
fi

# Set RMAN Catalog Password
#export RCATPASS=`ssh -a -o StrictHostKeyChecking=no -i ~oracle/.ssh/id_dsa_tdmorassh tdmorassh@pum.aetna.com retrieve --AccountName rcat_${RCATDB}_${DBName} --SystemName NMA_Oracle --ReasonText "RMAN Operation" | cut -f2 | tr -d '[[:space:]]'`

# Redirect standard output and standard error
exec > >(tee ${LOGOUT}) 2>&1

# Note Script Start Time
echo
echo "Script ${SCRIPT_NAME} Starting at "`date '+%Y-%m-%d %H:%M:%S'`

#********************************* Step #1 *********************************#
STEPNO=1
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 1 - Locking and killing AppD at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/lock_appD_account.sql
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/kill_appD_connections.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Locking and killing AppD"
   #exit 1
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
echo "Step 2 - Creating Drop User Statements For Target User ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_drop_target_users.sql ${DBAID}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating Drop User Statements For Target User ID's"
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
echo "Step 3 - Dropping Target User ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @drop_target_users.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Dropping Target User ID's"
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
echo "Step 4 - Creating Drop User Statements For Target Service ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/ext_drop_target_S_ids.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating Drop User Statements For Target Service ID's"
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
echo "Step 5 - Dropping Target Service ID's at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @drop_target_S_ids.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Dropping Target Service ID's"
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
echo "Step 6 - Setting Directory PATH at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set echo on feed on
 @replace_directory.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Setting Directory Path"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #7 *********************************#
STEPNO=7
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 7 - Create Preserved Unique Role(s) at "`date '+%Y-%m-%d %H:%M:%S'`

if [ -f ${DBName}_unique_role_privs_${RD}.sql ] ; then
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${DBName}_unique_role_privs_${RD}.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating Preserved Unique Role(s)"
   exit 1
fi
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
echo "Step 8 - Importing Preserved User ID's at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Import
impdp parfile=import_current_USERS_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Import Return Code
#RC=$?

# If Error Encountered
#if [ $RC -ne 0 ] ; then
#   echo
#   echo "Error Importing Preserved User ID's"
#   exit 1
#fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #9 *********************************#
STEPNO=9
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 9 - Importing Preserved Service ID's at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Import
impdp parfile=import_S_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Import Return Code
#RC=$?

# If Error Encountered
#if [ $RC -ne 0 ] ; then
#   echo
#   echo "Error Importing Preserved Service ID's"
#   exit 1
#fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #10 *********************************#
STEPNO=10
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 10 - Importing Preserved Strong Users at "`date '+%Y-%m-%d %H:%M:%S'`

# Run Import
impdp parfile=import_strong_users_table_${RD}.par << EOF
${DBAID}/${DBAPASS}
EOF

# Obtain Import Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Importing Preserved Strong Users"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #11 *********************************#
STEPNO=11
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 11 - Grant Directory Object Permissions at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 set echo on feed on
 @grant_directory.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Granting Directory Object Permissions"
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
echo "Step 12 - Disabling Data Guard Configuration at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/disable_dg.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Disabling Data Guard Configuration"
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
echo "Step 13 - Configuring RMAN at "`date '+%Y-%m-%d %H:%M:%S'`

rman << EOF
connect target /
connect catalog ${DBName}/${RCATPASS}@${RCATDB}
set echo on
@config.rman
show all;
EOF

# Obtain RMAN Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Configuring RMAN"
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
echo "Step 14 - Compiling Invalids at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/runutlrp.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Compiling Invalids"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #15 *********************************#
STEPNO=15
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 15 - Resize SGA and PGA at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${DBName}_change_sga_${RD}.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Resizing SGA and PGA"
   exit 1
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
echo "Step 16 - Shutting down DataBase ${DBName} at "`date '+%Y-%m-%d %H:%M:%S'`

${ORACLE_HOME}/bin/srvctl stop database -d ${DBName}_${HOST}

# Obtain Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Shutting Down DataBase"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #17 *********************************#
STEPNO=17
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 17 - Starting DataBase ${DBName} at "`date '+%Y-%m-%d %H:%M:%S'`

${ORACLE_HOME}/bin/srvctl start database -d ${DBName}_${HOST}

# Obtain Return Code
RC=$?

# If Error Encountered
if [ $RC -ne 0 ] ; then
   echo
   echo "Error Starting DataBase"
   exit 1
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
echo "Step 18 - List SGA and PGA Size at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/show_sga_pga.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Listing SGA and PGA Sizes"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#*****************************Step #19 *********************************************#
STEPNO=19
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 19 - Truncating Flux_Cluster Table at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/truncate_flux_cluster.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Truncating Flux_Cluster Table"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #20 *********************************#
STEPNO=20
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 20 - Changing SYS Password at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/change_sys_password.sql ${DBName} ${RD}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Changing SYS Password"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #21 *********************************#
STEPNO=21
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 21 - Changing HEDBA Password at "`date '+%Y-%m-%d %H:%M:%S'`

PASSDT=`date +%d%b`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/change_hedba_password.sql ${DBName} ${RD} ${PASSDT}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Changing HEDBA Password"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #22*********************************#
STEPNO=22
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 22 - Unlock Users at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${DBName}_unlock_user_accounts_${RD}.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error UnLocking Users"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #23 *********************************#
STEPNO=23
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 23 - Set AWR Snapshot Interval to 15 minutes at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 execute dbms_workload_repository.modify_snapshot_settings(interval => 15, retention => 89280);
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Setting AWR Snapshot Interval to 15 minutes"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #24 *********************************#
STEPNO=24
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 24 - Preserving Schema Owner and HE_CUSTOM Passwords  at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${DBName}_preserve_${SCHema}_pswd_${RD}.sql
 @${DBName}_preserve_HE_CUSTOM_pswd_${RD}.sql
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
#********************************* Step #25 *********************************#
STEPNO=25
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 25 - Grant special permissions to Performance Team "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/Perf_team_grants.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Granting special permissions to Performance Team"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi
#********************************* Step #26 *********************************#
STEPNO=26
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 26 - UnLocking AppD user at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/unlock_appD_account.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "UnLocking AppD"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi

#********************************* End Steps *********************************#

# Change Permissions
chmod 600 *.sql *.out *.log

echo
echo "Script ${SCRIPT_NAME} Ended at "`date '+%Y-%m-%d %H:%M:%S'`
echo

