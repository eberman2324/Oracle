#!/bin/sh

# Check for Input DataBase and Output Directory
if [ ${#} -ne 2 ]
then
 echo
 echo "Input DataBase and OutPut Directory Not Passed - Script Aborting"
 exit 0
fi

# Set DataBase Name
DBName=`echo $1|tr "[:lower:]" "[:upper:]"`

# Set Refresh Date
RD="$2"

# If Restart Confirm Directory Exists (May Be a Different Day)
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
. oraenv > oraenv_refresh_${DBName}.out 2>&1

# Set Email Distribution
MAILIDS=bermane@cvshealth.com

# Define OutPut File Name
DOW=`date |awk ' {print $1 }'`

# Remove File From Previous Run (If Exists)
if [ -f ${DBName}_user_names_${RD}.out ] ; then
   rm ${DBName}_user_names_${RD}.out
fi
# Extract User Names
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/get_user_names.sql '${DBName}' '${RD}'
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   mailx -s "${DBName} - Extract User Names Error" ${MAILIDS} < ${DBName}_user_names_${RD}.out
   exit 1
fi

# Declare Work Variable
typeset -i ERRCNT=0

# Remove File From Previous Run (If Exists)
if [ -f ${DBName}_user_privs_${RD}.out ] ; then
   rm ${DBName}_user_privs_${RD}.out
fi

# Loop Through User Names
cat ${DBName}_user_names_${RD}.out | while read usr
 do

 if test -n "$usr"
   then

# Extract User Information
sqlplus -s /nolog << EOF
 whenever sqlerror exit failure
 whenever oserror exit failure
 connect / as sysdba
 @/oradb/app/oracle/local/scripts/refresh/${DBName}/user_privs.sql '${DBName}' '${RD}' '${usr}'
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

