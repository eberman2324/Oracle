#!/bin/ksh

# Confirm Input Parameters
if [ ${#} -ne 5 ] ; then
   echo "Script Requires Five Input Parameters"
   exit 1
fi

# Set Input User
newuser=$1

# Set User Temporary Password
firstpassword=$2

# Set User Full Name
fullname="$3"
 
# Set User Email Address
emailaddress=$4


# Set DBA Email Address
dbaemailaddress=$5



#new standard
JOB_BASE=/oradb/app/oracle/local/scripts/security
JOB_WD=/oradb/app/oracle/local/scripts/security/logs






NOW=`/bin/date '+%m-%d-%Y-%H%M%S'`

TEMPLATE1=${JOB_BASE}/NEWUSER_MESSAGE4.INFO
TEMPLATE2=${JOB_BASE}/NEWUSER_MESSAGE2.INFO

DBNAMES=${JOB_WD}/${newuser}_dbnames.lst

send_email_script=$JOB_WD/send_email_$NOW.sh

send_email_output=$JOB_WD/send_email_$NOW.output

ZIPKEY=Alohomora

# Change Directory
cd $JOB_WD

echo " "

echo "# This is to send email to DBA" > $send_email_script 

#echo '------------------------------------------------------------------------------------------'
#echo "For user   " $newuser
#echo "password   " $firstpassword
#echo "email      " $emailaddress
#echo "Full name  " $fullname
#echo '------------------------------------------------------------------------------------------'
#echo " "

cat $TEMPLATE1 | /bin/sed -e "s/DATABASE_USERNAME/$newuser/g" | /bin/sed -e "s/FORMAL_NAME/$fullname/g" |
                 /bin/sed -e "s/xxx/$firstpassword/g" > $JOB_WD/$newuser.info

cat ${DBNAMES} >> $JOB_WD/$newuser.info
echo >> $JOB_WD/$newuser.info

cat ${TEMPLATE2} >> $JOB_WD/$newuser.info
echo >> $JOB_WD/$newuser.info

#echo -e '\nThe initial temporary password for user ' $newuser ' is ==>   ' $firstpassword '   <== ' > $JOB_WD/$newuser.txt
#echo -e '\nThe users email address is ' $emailaddress '   <== ' >> $JOB_WD/$newuser.txt
#echo -e '\n' >> $JOB_WD/$newuser.txt

#echo "#" >> $send_email_script
#echo "unix2dos " $newuser.txt >> $send_email_script
#echo "zip " $newuser".zip " $newuser".txt" >> $send_email_script
#echo 'mutt -s "New Oracle Database Account " -a ' $newuser'.zip  -- ' $dbaemailaddress' < ' $newuser'.info' >> $send_email_script
###mutt -s "New Oracle Database Account "  ${dbaemailaddress} <  ${newuser}.info >> $send_email_script
mutt -s "Oracle Database Account Temp Password " -c ${dbaemailaddress} ${emailaddress} <  ${newuser}.info >> $send_email_script
#echo "#" >> $send_email_script
#echo "ls -lrt " $newuser".txt" >> $send_email_script
#echo "ls -lrt " $newuser".zip " >> $send_email_script
echo "ls -lrt " $newuser".info" >> $send_email_script
#echo "#" >> $send_email_script
#echo "rm " $newuser".txt" >> $send_email_script
#echo "rm " $newuser".zip " >> $send_email_script
echo "rm " $newuser".info" >> $send_email_script
echo "#" >> $send_email_script

sleep 1

echo "# EOF" >> $send_email_script

#echo -e "\nSending email to DBA now\n"

chmod 700 $send_email_script

$send_email_script > $send_email_output 2>&1
RC=$?

if [ ${RC} -eq 0 ] ; then
   rm $send_email_output
   rm $send_email_script
fi

exit ${RC}

