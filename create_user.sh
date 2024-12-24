#!/bin/ksh

# Create user(s) in input database(s)
# 
# Script is driven by file ${CURDIR}/new_users.txt
#
# Sample file Entries
#
# A123456
# A234567
# A345678
#
# Sample Execution - create_user.sh HEDWQA HEDWQA2 HEDWQA3
#

# Set To Script Directory



#new standard
CURDIR="/oradb/app/oracle/local/scripts/security"



# Change Directory
cd ${CURDIR}

clear

# Confirm Input Database(s)
if [ ${#} -eq 0 ] ; then
   echo "Must Enter at least one Input Database Name"
   exit 1
else
   DBCNT=${#}
fi

# Confirm File of New Users Exist
if [ ! -f new_users.txt ] ; then
   echo "New users file new_users.txt not found - script aborting"
   exit 1
else
   chmod 600 new_users.txt
fi

# Declare Work Variables
export integer ADDCNT=0
export integer COLERR=0
export integer EMCNT=0
export integer ERRCNT=0
export integer i=0
export integer LOOPADDCNT=0
export integer NUMCOL=0
export integer RECCNT=0
export integer SUSERCNT=0
export integer USERCNT=0
export integer USERFOUNDCNT=0




# Make Sure Each Line In File Has One Value
COLERR=`awk 'NF != 1 {print 1}' new_users.txt`
if [ "${COLERR}" -eq 1 ] ; then
   echo "Not all rows in file new_users.txt has only one column value - script aborting"
   exit 1
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

echo "Enter Non-Prod DataBase DBA Password"
read DBANPASS

# Confirm DBA Password Entered
if [ -z "${DBANPASS}" ]; then
   echo
   echo "Must Enter Non-Prod DataBase DBA Password"
   exit 1
fi

# Confirm ICRPRD Access
#sqlplus -s <<EOF > /dev/null
# ${DBAID}/${DBANPASS}@ICRPRD
# whenever sqlerror exit failure;
# select global_name from global_name;
#EOF

# Set Return Code
#RC=$?

# If Error Encountered
#if [ ${RC} -ne 0 ]; then
#$   echo
#   echo "Error Connecting to ICRPRD Using Non-Prod DBA Password"
#   exit 1
#fi

echo "Enter Prod DataBase DBA Password"
read DBAPASS

# Confirm DBA Password Entered
if [ -z "${DBAPASS}" ]; then
   echo
   echo "Must Enter Prod DataBase DBA Password"
   exit 1
fi

# Set DBA Email
case ${DBAID} in
     "A738300")
     export DBAEMA=schloendornt1@cvshealth.com
     ;;
     "A236120")
     export DBAEMA=bermane@cvshealth.com
     ;;
     "A607483")
     export DBAEMA=lxshen@cvshealth.com
     ;;
     "A229515")
     export DBAEMA=LuddyM@cvshealth.com
     ;;
     *)
     echo "Enter DBA Email Address"
     read DBAEMA
     if [ -z "${DBAEMA}" ]; then
        echo
        echo "Must Enter DBA Email Address"
        exit 1
     fi
     ;;      
esac

# Confirm Email is an Aetna Address
#EMCNT=`echo ${DBAEMA} |grep -i "aetna.com"|wc -l`
EMCNT=`echo ${DBAEMA} |grep -i "cvshealth.com\|aetna.com"|wc -l`
if [ ${EMCNT} -eq 0 ]; then
   echo
   echo "Email Adress Must Be an Aetna Email Address For DBA ${DBAID} "
   exit 1
fi

echo "Do You Want To Expire The Users Password (Y or N)"
read EP

# Confirm Expire Password Entered
if [ -z "${EP}" ]; then
   echo
   echo "Must Enter Response To Expiring The Password"
   exit 1
fi

# Upper Case Expire Password Response
typeset -u EP

# Confirm Valid Response
if [ ${EP} != "Y" ];then
 if [ ${EP} != "N" ]; then
    echo
    echo "Expire Password Response Must Be Y or N"
    exit 1
 fi
fi

# Remove File From a Previous Run
if [ -f dbnames_${DBAID}.lst ] ; then
   rm dbnames_${DBAID}.lst
fi


# Generate Temporary Password
# Not calling function due to it being SYS owned
PART1=`cat /dev/urandom | tr -dc a-z|head -c1`
PART2=`cat /dev/urandom | tr -dc a-z|head -c1`
PART3=`cat /dev/urandom | tr -dc A-Z|head -c1`
PART4=`cat /dev/urandom | tr -dc A-Z|head -c1`
PART5="#"
PART6=`cat /dev/urandom | tr -dc 0-9|head -c1`
PART7=`cat /dev/urandom | tr -dc A-Z-a-z0-9|head -c1`
PART8=`cat /dev/urandom | tr -dc A-Z-a-z0-9|head -c1`
PASS_RANDOM="${PART1}${PART2}${PART3}${PART4}${PART5}${PART6}${PART7}${PART8}"



# Initialize
i=1

# Save Database Names To A file
while [[ $i -le ${DBCNT} ]] ; do

  DBName=$1

  typeset -u DBName

  echo ${DBName} >> dbnames_${DBAID}.lst

  shift

  ((i = $i + 1))

done

# Set To Current Date/Time
export DATEV="`date +%Y%m%d_%T`"

# Clear Screen To Hide Input DBA Password
clear

# Loop Through New Users File
cat new_users.txt |while read NEWUSER

do

# Increment Record Counter
((RECCNT = ${RECCNT} + 1))

# Define Log File
LOGFILE=${CURDIR}/logs/create_user_${NEWUSER}_${DATEV}.log

# Initialize
ADDCNT=0

# Confirm New User ID Entered
if [ -z "${NEWUSER}" ]; then
   echo >> ${LOGFILE}
   echo "Must Enter New User ID" >> ${LOGFILE}
   echo >> ${LOGFILE}
   echo "Skipping Record Number ${RECCNT} in file"
   echo >> ${LOGFILE}
   ERRCNT=1
   continue
fi

# Upper Case User ID
typeset -u NEWUSER

# Get Information From Active Directory
sqlplus -s <<EOF > /dev/null
${DBAID}/${DBANPASS}@HEPYDEV
whenever sqlerror exit failure;
@get_ldap_user_info_new.sql ${NEWUSER}
EOF

# Set Return Code
RC=$?

# If User Found In Active Directory
if [ ${RC} -eq 0 ] ; then
 if [ -f ldap_user_${NEWUSER}.out ] ; then
    echo `cat ldap_user_${NEWUSER}.out` > ldap_user_${NEWUSER}.out
    NUMCOL=`cat ldap_user_${NEWUSER}.out|awk -F ":" '{print NF}'`
    if [ ${NUMCOL} -eq 3 ] ; then
       FN=`cat ldap_user_${NEWUSER}.out|awk -F ":" '{print $1}'`
       LN=`cat ldap_user_${NEWUSER}.out|awk -F ":" '{print $2}'`
       EMA=`cat ldap_user_${NEWUSER}.out|awk -F ":" '{print $3}'`
echo "========================================================================================================="
echo "First Name: " $FN
echo "Last Name : " $LN
echo "email addr: " $EMA
echo "========================================================================================================="
    else
       RC=1
    fi
 fi
fi

if [ -f ldap_user_${NEWUSER}.out ] ; then
   rm ldap_user_${NEWUSER}.out
fi

# Confirm User Email Found
if [ ${NUMCOL} -ne 3 ] ; then
   echo "Enter Email Address For ${NEWUSER}"
   read EMA < /dev/tty
   if [ -z "${EMA}" ]; then
      echo >> ${LOGFILE}
      echo "Email Address Not Found For ${NEWUSER} " >> ${LOGFILE}
      echo >> ${LOGFILE}
      echo "Skipping Record Number ${RECCNT} in file" >> ${LOGFILE}
      echo >> ${LOGFILE}
      ERRCNT=1
      continue
   fi
fi

# Confirm Email is an Aetna Address
EMCNT=`echo ${EMA} |grep -i "cvshealth.com\|aetna.com"|wc -l`
if [ ${EMCNT} -eq 0 ]; then
   echo >> ${LOGFILE}
   echo "Email Adress Must Be an Aetna Email Address For User ${NEWUSER} " >> ${LOGFILE}
   echo >> ${LOGFILE}
   echo "Skipping Record Number ${RECCNT} in file" >> ${LOGFILE}
   echo >> ${LOGFILE}
   ERRCNT=1
   continue
fi

# Confirm User First Name Entered
if [ ${NUMCOL} -ne 3 ] ; then
   echo "Enter First Name For ${NEWUSER}"
   read FN < /dev/tty
   if [ -z "${FN}" ]; then
      echo >> ${LOGFILE}
      echo "First Name Not Found For User ${NEWUSER} " >> ${LOGFILE}
      echo >> ${LOGFILE}
      echo "Skipping Record Number ${RECCNT} in file" >> ${LOGFILE}
      echo >> ${LOGFILE}
      ERRCNT=1
      continue
   fi
fi

# Confirm User Last Name Entered
if [ ${NUMCOL} -ne 3 ] ; then
   echo "Enter Last Name For ${NEWUSER}"
   read LN < /dev/tty
   if [ -z "${LN}" ]; then
      echo >> ${LOGFILE}
      echo "Last Name Not Found For User ${NEWUSER} " >> ${LOGFILE}
      echo >> ${LOGFILE}
      echo "Skipping Record Number ${RECCNT} in file" >> ${LOGFILE}
      echo >> ${LOGFILE}
      ERRCNT=1
      continue
   fi
fi

#set -x
#echo "BEFORE RANDOM"


#echo "After RANDOM"
#set +x

#########################################################################
PASS="Time2chng#"
#PASS="PlzChange#"
#PASS+="`date +%Y%b%d`"
#echo -e "\nTemp Password is: " ${PASS}
#########################################################################

# Remove Work File From a Previous Failed Run
if [ -f ${CURDIR}/logs/${NEWUSER}_dbnames.lst ] ; then
   rm  ${CURDIR}/logs/${NEWUSER}_dbnames.lst
fi

# Set Oracle Environment
export ORAENV_ASK=NO
export ORACLE_SID=HEPYDEV
ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
. ${ORACLE_HOME}/bin/oraenv >> ${CURDIR}/logs/${NEWUSER}_oraenv.out 2>&1

echo "Starting Create New User Process at "`date` >> ${LOGFILE}
echo >> ${LOGFILE}


#echo "Debug step 1 " >> ${LOGFILE}

# Loop Through Each Input Database
cat dbnames_${DBAID}.lst |while read DBName

do

#echo "Debug step 2 " >> ${LOGFILE}

# Set Oracle SID
export ORACLE_SID=${DBName}

# Initialize Loop Counters
SUSERCNT=0
USERCNT=0
USERFOUNDCNT=0

# Confirm Valid PAYOR Database
case ${ORACLE_SID} in
     "HEDWCFG"|"HEPYCFG"|"HEPYDBA"|"HEMPTST"|"HEGETST"|"HEPYDEV"|"HEPYDEV2"|"HEPYDEV3"|"HEPYMGR2"|"HEPYTST"|"HEPYQA"|"HEPYQA2"|"HEPYQA3"|"HEPYSTS"|"HEPYUAT"|"HEPYPRD"|"HEDWDEV"|"HEDWDEV2"|"HEDWDEV3"|"HEDWMGR2"|"HEDWQA"|"HEDWQA2"|"HEDWQA3"|"HEDWSTS"|"HEDWUAT"|"HEDWPRD"|"HECVDEV"|"HECVDEV2"|"HECVDEV3"|"HECVSTS"|"HECVQA"|"HECVQA2"|"HECVQA3"|"HECVUAT"|"HECVPRD"| "HEMPDEV"|"HEMPDEV2"|"HEMPDEV3"|"HEMPSTS"|"HEMPMGR"|"HEMPMGR2"|"HEMPQA"|"HEMPQA2"|"HEMPQA3"|"HEMPUAT"|"HEMPPRD"|"MPSBOX01"|"MPSBOX02"|"HEMPQA4"|"HEGEREF"|"HEGEREF2"|"HEGEREF3"|"HEGESAND"|"HEGEDEV"|"HEGEDEV2"|"HEGEDEV3"|"HEGESTS"|"HEGEQA"|"HEGEQA2"|"HEGEQA3"|"HEGEUAT"|"HEGEMGR"|"HEGEPRD")
     ;;
     *)
     echo >> ${LOGFILE}
     echo "${ORACLE_SID} not a recognized PAYOR or DW database - database skipped" >> ${LOGFILE}
     echo >> ${LOGFILE}
     continue
     ;;      
esac

# Set DataBase Connection Password
CNT=`echo ${ORACLE_SID}|grep "PRD"|wc -l`
if [ ${CNT} -eq 0 ] ; then
   CONNPASS=${DBANPASS}
else
   CONNPASS=${DBAPASS}
fi

# Confirm User Does Not Exist In DataBase
USERCNT=`sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
set feed off head off pagesize 0
select count(*)
from dba_users
where username = '${NEWUSER}';
EOF`



# If Database User Exists
if [ ${USERCNT} -eq 1 ] ; then
   echo "User ${NEWUSER} Already Exists in Database ${DBName}" >> ${LOGFILE}
   echo "  User ${NEWUSER} Already Exists in Database ${DBName}"
   USERFOUNDCNT=1
fi

# Confirm User Does Not Exist In Strong Users Table
SUSERCNT=`sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
set pagesize 0 head off feed off
select count(*)
from   aedba.strong_users
where  upper(username) = '${NEWUSER}';
EOF`

# If Strong User Exists
if [ ${SUSERCNT} -eq 1 ] ; then
   echo "User ${NEWUSER} Already exists in strong users table in database ${DBName}" >> ${LOGFILE}
   echo "  User ${NEWUSER} Already exists in strong users table in database ${DBName}"
   ((USERFOUNDCNT = $USERFOUNCNT + 1))
fi

# If User Exists - Skip The DataBase
if [ ${USERFOUNDCNT} -gt 0 ] ; then
   ##ERRCNT=1
   ##continue
#echo "User ${NEWUSER} already exists in ${DBName}" >> ${LOGFILE}   
echo "Issuing new Temp password for ${NEWUSER} in database ${DBName}" >> ${LOGFILE}   
sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
whenever sqlerror exit failure;
set pagesize 0 head off feed off
alter user ${NEWUSER} identified by "${PASS_RANDOM}";
alter user ${NEWUSER} account unlock;
alter user ${NEWUSER} password expire;
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Issuing New User ${NEWUSER} temp password in DataBase ${DBName}" >> ${LOGFILE}
   ERRCNT=1
   continue
fi

# Add Database Name To File
echo ${DBName} >> ${CURDIR}/logs/${NEWUSER}_dbnames.lst

# Add DataBase Name To Log
echo "User ${NEWUSER} new temp password issued and account pre expired in ${DBName}" >> ${LOGFILE}
echo >> ${LOGFILE}

# Increment Valid User Count
((ADDCNT = $ADDCNT + 1))
((LOOPADDCNT = $LOOPADDCNT + 1))




else   

echo "Adding ${NEWUSER} to strong users table in database ${DBName}" >> ${LOGFILE}
echo "  Adding ${NEWUSER} to strong users table in database ${DBName}"

# Add User to Strong User Table
sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
whenever sqlerror exit failure;
@add_strong_user.sql ${NEWUSER} ${EMA} ${LN} ${FN}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Adding User ${NEWUSER} to Strong Users Table in DataBase ${DBName}" >> ${LOGFILE}
   ERRCNT=1
   continue
fi

#echo "Just added user into strong_user table "
#echo "  ========================================================================================================="
#echo "    newuser   : " ${NEWUSER}
#echo "    first pwd : " ${PASS}
#echo "    First Name: " ${FN}
#echo "    Last Name : " ${LN}
#echo "    email addr: " ${EMA}
#echo "========================================================================================================="

echo "Adding ${NEWUSER} to dba_users in database ${DBName}" >> ${LOGFILE}
echo "  Adding ${NEWUSER} to dba_users in database ${DBName}"

# Add User To DataBase
sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
whenever sqlerror exit failure;
@create_user.sql ${NEWUSER} ${PASS}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Adding User ${NEWUSER} to DataBase ${DBName}" >> ${LOGFILE}
   ERRCNT=1
   continue
fi

echo "Confirming password for ${NEWUSER} in database ${DBName}" >> ${LOGFILE}

# Confirm New User Can Access DataBase
sqlplus -s <<EOF
${NEWUSER}/${PASS}@${DBName}
whenever sqlerror exit failure;
@testuser.sql
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Connecting to DataBase ${DBName} as User ${NEWUSER}" >> ${LOGFILE}
   ERRCNT=1
   continue
fi

# Expire New User Password (May Not Want To If HE Employee)
if [ ${EP} = "Y" ] ; then
echo "Expiring password for user ${NEWUSER} in database ${DBName}" >> ${LOGFILE}
sqlplus -s <<EOF
${DBAID}/${CONNPASS}@${DBName}
whenever sqlerror exit failure;
@expire_user.sql ${NEWUSER}
EOF

# If Error
if [ $? -ne 0 ] ; then
   echo "Error Expiring New User Password in DataBase ${DBName} for User ${NEWUSER}" >> ${LOGFILE}
   ERRCNT=1
   continue
fi
fi

# Add Database Name To File
echo ${DBName} >> ${CURDIR}/logs/${NEWUSER}_dbnames.lst

# Add DataBase Name To Log
echo "User ${NEWUSER} added to database ${DBName}" >> ${LOGFILE}
echo >> ${LOGFILE}

# Increment Valid User Count
((ADDCNT = $ADDCNT + 1))
((LOOPADDCNT = $LOOPADDCNT + 1))
fi



# End DataBase Loop
done

# Send New User Info To DBA
if [ ${ADDCNT} -gt 0 ] ; then
    if [ ${USERFOUNDCNT} -gt 0 ] ; then
       ${CURDIR}/send_new_user_email_v3.sh ${NEWUSER} ${PASS_RANDOM} "${FN} ${LN}" ${EMA} ${DBAEMA}
    else
	   ${CURDIR}/send_new_user_email_v2.sh ${NEWUSER} ${PASS} "${FN} ${LN}" ${EMA} ${DBAEMA}
    fi
   if [ $? -ne 0 ] ; then
      echo "Error Encountered in script send_new_user_email.sh" >> ${LOGFILE}
      ERRCNT=1
   fi
fi

# Append To Log
echo >> ${LOGFILE}
echo "End Create New User Process at "`date` >> ${LOGFILE}
echo >> ${LOGFILE}

# Remove Work File
rm ${CURDIR}/logs/${NEWUSER}_oraenv.out

# Remove Work File
if [ -f ${CURDIR}/logs/${NEWUSER}_dbnames.lst ] ; then
   rm  ${CURDIR}/logs/${NEWUSER}_dbnames.lst
fi

# End New User Loop
done

# Display Message
if [ ${ERRCNT} -gt 0 ] ; then
   echo
   echo "Script Encountered Errors"
   echo "See Log File(s) In Directory ${CURDIR}/logs For Details"
else
   echo
   echo "Script Complete"
   echo "See Log File(s) In Directory ${CURDIR}/logs For Details"
fi

# If at least one user added - move file
if [ ${LOOPADDCNT} -gt 0 ] ; then
   mv new_users.txt ${CURDIR}/logs/new_users.txt_${DATEV}
fi

# Change File Permissions
chmod 600 ${CURDIR}/logs/*.log

# Remove File
if [ -f dbnames_${DBAID}.lst ] ; then
   rm dbnames_${DBAID}.lst
fi
###  EOF
