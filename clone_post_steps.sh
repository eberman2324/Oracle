#!/bin/bash

#############################################################################
# Script Name :    clone_post_steps.sh                                      #
#                                                                           #
# Purpose     :    To be run after a clone refresh                          #
#                                                                           #
# Step        :    (1) Change SYS Password				    #
#             :    (2) Apply Grants To OPTIM Role                           #
#             :    (3) Create OPTIM user     				    #
#             :    (4) Apply Grants To OPTIM Se rvice Account               #
#             :    (5) Create OPTIM Package                                 #
#             :    (6) Grant Explicit Privs to Service ID                   #
#             :    (7) Compile Invalids                                     #
#             :    (8) Create lock user accounts script                     #
#             :    (9) Lock user accounts                                   #
#             :   (10) Add Indexes                                          #
#             :   (11) Change sga and pga                                   #
#             :   (12) Shutdown DB                                          #
#             :   (13) Startup DB                                           #
#             :   (14) Configure RMAN                                       #
#             :   (15) Configure RMAN DDBoost                               #
#             :   (16) Truncate Table(s)                                    #
#             :   (17) Generate Tables List and email                       #
#             :            						    #
# Required    :                                                             #
# Parameters  :  Script Prompts For Input Parameters                        #
#                                                                           #
# Initial Date:  11/11/2020                                                 #
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
     "HEPYDEV"|"HEPYDEV2"|"HEPYDEV3"|"HEPYQA"|"HEPYQA2"|"HEPYQA3"|"HEPYSTS"|"HEPYUAT"|"HEPYMASK")
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

#echo "Enter Directory Where Clone Pre Run Scripts Reside (Format: Mon_DD_YYYY)"
#read RD



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
if [ $STEPRST -lt 1 ] || [ $STEPRST -gt 31 ]; then
   echo
   echo "Restart Step Must Be Between 1-31"
   exit 1
fi

# Set Script Name
SCRIPT_NAME=`basename $0`

# Set RMAN Catalog
export RCATDB=RCATDEV

# Change To Output Directory

#cd ${HOME}/${DBName}/refresh
#cd ${HOME}/tls/refresh/${DBName}

cd ${SCRIPTS}/refresh/${DBName}
rm *.out *.log

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
#MAILIDS=schloendornt1@aetna.com
#MAILIDS=bermane@aetna.com
MAILIDS=`paste -s ${SCRIPTS}/refresh/${DBName}/dba_mail_list`

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
      exit 1
   fi
fi

# Set RMAN Catalog Password

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
echo "Step 1 - Changing SYS Password at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/change_sys_password.sql ${DBName}
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


#********************************* Step #2 *********************************#
STEPNO=2
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 2 - Apply Grants To OPTIM Role at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/optim_role_grants.sql ${DBName} 
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Granting To OPTIM Role"
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
echo "Step 3 - Create OPTIM user at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/create_OPTIM_user.sql ${DBName}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating OPTIM user"
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
echo "Step 4 - Apply Grants To OPTIM Service Account at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/grant_for_optim.sql ${DBName}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Applying Grants To OPTIM Service Account"
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
echo "Step 5 - Create OPTIM Package at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/create_optim_package.sql ${DBName}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Creating OPTIM Package"
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
echo "Step 6 - Grant Explicit Privs to Service ID at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/grant_OPTIM_USER.sql ${DBName}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Granting Explicit Privs to Service ID"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi

#********************************* Step 7 *********************************#
STEPNO=7
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 7 - Compiling Invalids at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/runutlrp.sql ${DBName}
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

#********************************* Step 8 *********************************#
STEPNO=8
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 8 - create lock user accounts script at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/ext_lock_user_accounts.sql ${DBName}
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error create lock user accounts script"
   exit 1
fi

else
  echo
  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
fi

#********************************* Step 9 *********************************#
#STEPNO=9
#if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
#then

#echo
#echo "Step 9 -  Lock user accounts at "`date '+%Y-%m-%d %H:%M:%S'`

#sqlplus -s /nolog << EOF
# whenever sqlerror exit failure
# whenever oserror exit failure
# connect / as sysdba
# @${SCRIPTS}/refresh/${DBName}/${DBName}_lock_user_accounts.sql
#EOF

# Obtain SQLPlus Return Code
#SQLRC=$?

# If Error Encountered
#if [ $SQLRC -ne 0 ] ; then
#   echo
#   echo "Error Locking user accounts"
#   exit 1
#fi

#else
#  echo
#  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
#fi

#********************************* Step 10 *********************************#
STEPNO=10
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 10 -  Add Indexes in support of Masking at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/create_indexes.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Adding indexes"
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
echo "Step 11 - Resize SGA/PGA and disable dg at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/change_sga.sql
 @${SCRIPTS}/refresh/${DBName}/disable_dg.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Resizing SGA/PGA and disabling dg"
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
echo "Step 12 - Shutting down DataBase ${DBName} at "`date '+%Y-%m-%d %H:%M:%S'`

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
#********************************* Step #13 *********************************#
STEPNO=13
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 13 - Starting DataBase ${DBName} at "`date '+%Y-%m-%d %H:%M:%S'`

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
#********************************* Step #14 *********************************#
STEPNO=14
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 14 - Configuring RMAN at "`date '+%Y-%m-%d %H:%M:%S'`

rman << EOF
connect target /
connect catalog ${DBName}/${RCATPASS}@${RCATDB}
set echo on
@${SCRIPTS}/refresh/${DBName}/config.rman
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
#STEPNO=15
#if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
#then

#echo
#echo "Step 15 - Configuring original RNAN DDBoost settings at "`date '+%Y-%m-%d %H:%M:%S'`

#rman << EOF
#connect target /
#connect catalog ${DBName}/${RCATPASS}@${RCATDB}
#set echo on
#@${SCRIPTS}/refresh/${DBName}/configure_ddboost.rman
#show all;
#EOF

# Obtain RMAN Return Code
#SQLRC=$?

# If Error Encountered
#if [ $SQLRC -ne 0 ] ; then
#   echo
#   echo "Error original RMAN DDBoost settings"
#   exit 1
#fi

#else
#  echo
#  echo "Bypassing STEP ${STEPNO} For STEP ${STEPRST} Restart"
#fi
#********************************* Step 16 *********************************#
STEPNO=16
if [ $STEPRST -lt $STEPNO -o $STEPRST -eq $STEPNO ]
then

echo
echo "Step 16 -  Truncate table(s) in support of Masking at "`date '+%Y-%m-%d %H:%M:%S'`

sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @${SCRIPTS}/refresh/${DBName}/truncate_tbl.sql
 @${SCRIPTS}/refresh/${DBName}/truncate_job.sql
EOF

# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Truncating Table"
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
echo "Step 17 - Generate and email Table List "`date '+%Y-%m-%d %H:%M:%S'`


${SCRIPTS}/refresh/${DBName}/get_Table_List.sh ${DBName}


# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Generating Table List"
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

