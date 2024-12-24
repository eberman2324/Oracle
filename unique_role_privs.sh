#!/bin/sh

# Check for Input AUX DataBase, Output Directory, Target DataBase, DBAID, DBAPASS
if [ ${#} -ne 5 ]
then
 echo
 echo "Input DataBase, OutPut Directory, Target DataBase, DBAID, DBAPASS Not Passed - Script Aborting"
 exit 1
fi

# Set DataBase Name
DBName=`echo $1|tr "[:lower:]" "[:upper:]"`

# Set Refresh Date
RD="$2"

# Set Target DataBase Name
TARGETDB=`echo $3|tr "[:lower:]" "[:upper:]"`

# Set DBA ID
DBAID=`echo $4|tr "[:lower:]" "[:upper:]"`

# Set DBA PassWord
DBAPASS="$5"

# Confirm Directory Exists
if [ ! -d /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} ] ; then
    echo
    echo "Directory /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD} Not Found - Script Aborting"
    exit 1
fi

# Change Directory
cd /oradb/app/oracle/local/scripts/refresh/${DBName}/${RD}

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > oraenv_unique_role_privs.out 2>&1

# Set Email Distribution
MAILIDS=bermane@cvshealth.com

# Remove File From Previous Run (If Exists)
if [ -f ${DBName}_unique_role_names_${RD}.out ] ; then
   rm ${DBName}_unique_role_names_${RD}.out
fi
# Extract Role Names
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect ${DBAID}/${DBAPASS}
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/get_unique_role_names.sql '${DBName}' '${RD}' '${TARGETDB}'
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   mailx -s "${DBName} - Extract Unique Role Names Error" ${MAILIDS} < ${DBName}_unique_role_names_${RD}.out
   exit 1
fi

# Declare Work Variable
typeset -i ERRCNT=0

# Remove File From Previous Run (If Exists)
if [ -f ${DBName}_unique_role_privs_${RD}.sql ] ; then
   rm ${DBName}_unique_role_privs_${RD}.sql
fi

# Loop Through User Names
cat ${DBName}_unique_role_names_${RD}.out | while read role
 do

 if test -n "$role"
   then

# Extract Role Information
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/unique_role_privs.sql '${DBName}' '${RD}' '${role}'
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   ((ERRCNT = $ERRCNT + 1))
fi

 fi

done

# Change File Permissions
chmod 600 *.out

if [ $ERRCNT -eq 0 ] ; then
   exit 0
else
   exit 1
fi

