#!/bin/ksh

clear

# Confirm Input Database(s)
if [ ${#} -eq 0 ] ; then
   echo "Must Enter at least one Input Database Name"
   exit 1
else
   DBCNT=${#}
fi

echo "Enter DBA ID"
read DBAID

# Confirm DBA ID Entered
if [ -z "${DBAID}" ]; then
   echo
   echo "Must Enter DBA ID"
   exit 1
fi

# Upper Case DBA ID
typeset -u DBAID

echo "Enter DBA Password"
read DBAPASS

# Confirm DBA Password Entered
if [ -z "${DBAPASS}" ]; then
   echo
   echo "Must Enter DBA Password"
   exit 1
fi

# Initialize
integer i=1
integer ERRCNT=0

# Set To Script Directory
SCRDIR="/home/oracle/tls/rman"

# Change Directory
cd ${SCRDIR}/logs

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=HEDWSTS
ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
. ${ORACLE_HOME}/bin/oraenv > /dev/null

# Set DateTime
DATE=`date +%m:%d:%y_%H:%M:%S`

# Define OutPut Log File
LOGOUT=drop_restore_point_${DATE}.log

# Drop File From Previous Run
if [ -f drop_restore_point.out ] ; then
   rm drop_restore_point.out
fi

clear

# Redirect standard output and standard error to log file
exec 1> ${LOGOUT} 2>&1

# Loop Through Each Input Database
while [[ $i -le $DBCNT ]] ; do

# Set To Input Database Name (i)
DBName=$1
typeset -u DBName

# Set Oracle SID
export ORACLE_SID=${DBName}

# Set To Next Database
if [ $i -lt $DBCNT ] ; then
   shift
fi

# Increment Loop Counter
((i = $i + 1))

# Confirm Valid DW Database
case ${DBName} in
     "HEDWDEV"|"HEDWDEV2"|"HEDWDEV3"|"HEDWTST"|"HEDWQA"|"HEDWQA2"|"HEDWQA3"|"HEDWSTS"|"HEDWUAT"|"HEDWMGR"|"HEDWMGR2")
     ;;
     *)
     echo
     echo "${ORACLE_SID} not a recognized DW database - database skipped"
     echo
     continue
     ;;
esac

# Drop Restore Point(s)
sqlplus -s <<EOF
${DBAID}/${DBAPASS}@${DBName}
whenever sqlerror exit failure
@${SCRDIR}/ext_drop_restore_point.sql
@drop_restore_point.sql
EOF

# If Error Encountered
if [ $? -ne 0 ] ; then
   echo "Error Encountered in DataBase ${DBName}"
   ((ERRCNT = $ERRCNT + 1))
fi

# End Loop
done

# Change Permissions
chmod 600 ${LOGOUT} drop_restore_point.out

