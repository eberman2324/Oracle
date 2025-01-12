#!/bin/ksh
###################################################################################################
# NEWUSER 3.22	Modified October 7, 2016  
# Use this process to create new oracle users
# Version 1.0	used SYS.strong_users and sys.strong_log(Last modified Modified May 12, 2015)
# Version 2.0 	used AETNADBA.strong_users and AETNADBA.strong_log
# Version 3.0	requires AEDBA.strong_users and AEDBA.strong_log to exist
# V3.22		updated for NextGen Oracle 12c	(Last modified 10/7/2016)
#		READ_ONLY ROLE WAS CHANGED TO APP_USER_ROLE 
# Version 4.0   Accomodate new vm build standard
###################################################################################################

source ~oracle/std.env
JOB_BASE=$STD_DBMS_DIR/app/oracle/local/scripts
JOB_WD=$STD_DBMS_DIR/app/oracle/local/logs

NOW=`/bin/date '+%m-%d-%Y-%H%M%S'`
TEMPLATE=$JOB_BASE/TEMPLATE_4_NEWUSER.INFO
PASSWORD_RULES=$JOB_BASE/PASSWORD_RULES_4_NEWUSER.INFO

new_users_file=$JOB_WD/new_strong_users_$NOW.inn
send_emails_script=$JOB_WD/send_emails_$NOW.sh
send_emails_output=$JOB_WD/send_emails_$NOW.output

ZIPKEY=Alohomora
###################################################################################################
cd $JOB_WD
echo " "
echo "PWD = " `pwd`
echo " "

echo "# This is to send emails to new users" > $send_emails_script 
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" << EOF > $new_users_file
@SHOW_NEW_STRONG_USERS.sql
EOF

#sleep 1

###################################################################################################
cat $new_users_file | while read thishost thisdatabase newuser firstpassword emailaddress fullname
do

###################################################################################################
# REMOVED!!!  LDAP resolves this issue
# TNSPING exits the loop
# IF database can not TNSPING; only  1 use will be created at a time since the loop exist on error
# Modified May 12, 2015
#
###################################################################################################
## ##$ORACLE_HOME/bin/tnsping $thisdatabase
## ##RC=$?
## ##echo "Return Code = " $RC
## ##if [[ $RC != 0 ]] ; then
## ##    echo '------------------------------------------------------------------------------------------'
## ##    echo '------------------------------------------------------------------------------------------'
## ##    echo "TNSPING of " $thisdatabase " Failed!!!"
## ##    echo "Please add " $thisdatabase " to TNSNAMES.ora before proceeding! "
## ##    echo '------------------------------------------------------------------------------------------'
## ##    echo '------------------------------------------------------------------------------------------'
## ##    exit 10
## ##fi

echo '------------------------------------------------------------------------------------------'
echo "On server  " $thishost
echo "On database" $thisdatabase
echo "For user   " $newuser
echo "password   " $firstpassword
echo "email      " $emailaddress
echo "Full name  " $fullname
echo '------------------------------------------------------------------------------------------'
echo " "
cat $TEMPLATE | /bin/sed -e "s/HOST_NAME/$thishost/g"  |
                        /bin/sed -e "s/DATABASE_NAME/$thisdatabase/g" |
                        /bin/sed -e "s/DATABASE_USERNAME/$newuser/g" |
                        /bin/sed -e "s/FORMAL_NAME/$fullname/g"           > $JOB_WD/$newuser-$thisdatabase.info

cat $PASSWORD_RULES >> $JOB_WD/$newuser-$thisdatabase.info

# $JOB_WD/$newuser-$thisdatabase.txt is TEST NEW USER output which will go to user
# $JOB_WD/$newuser-$thisdatabase.txt2 is the CREATE and EXPIRE pieces which will go nowhere
echo -e '\n\nThe initial temporary password for user ' $newuser ' is ==>   ' $firstpassword '   <== ' > $JOB_WD/$newuser-$thisdatabase.txt
echo -e '\n\n\n' >> $JOB_WD/$newuser-$thisdatabase.txt
echo 'USERS ARE REQUIRED TO CHANGE THIS PASSWORD UPON YOUR FIRST SUCCESSFUL LOGIN ATTEMPT.  ' >> $JOB_WD/$newuser-$thisdatabase.txt
echo -e '\n\n\n' >> $JOB_WD/$newuser-$thisdatabase.txt

###################################################################################################
echo '-----------------------------------------------------------------------------------------------' > $JOB_WD/$newuser-$thisdatabase.txt2
echo '-- Create User Script -------------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt2
$ORACLE_HOME/bin/sqlplus "/ as sysdba" << EOF2 >> $JOB_WD/$newuser-$thisdatabase.txt2
@CREATE_NEW_USER.sql $newuser $firstpassword
EOF2
###################################################################################################
echo -e '\n\n\n' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '-----------------------------------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '-- Test New User Script -----------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '|' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '|' >> $JOB_WD/$newuser-$thisdatabase.txt
echo 'V' >> $JOB_WD/$newuser-$thisdatabase.txt
echo "echodo sqlplus '$newuser/$firstpassword'@$thisdatabase @TESTUSER.sql " > $newuser.sh
chmod 755 $newuser.sh
./$newuser.sh >>  $JOB_WD/$newuser-$thisdatabase.txt
###################################################################################################
echo -e '\n\n\n' >> $JOB_WD/$newuser-$thisdatabase.txt2
echo '-----------------------------------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt2
echo '-- Pre-expire Password Script -----------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt2
$ORACLE_HOME/bin/sqlplus "/ as sysdba" << EOF4 >> $JOB_WD/$newuser-$thisdatabase.txt2
@EXPIRE_NEW_USER.sql $newuser
EOF4
###################################################################################################
#$ORACLE_HOME/bin/sqlplus "/ as sysdba" << EOF5 >> $JOB_WD/$newuser-$thisdatabase.killed
#@DROP_NEW_USER.sql $newuser
#EOF5
###################################################################################################
echo -e '\n\n\n' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '-----------------------------------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt
echo '-- EOF ----------------------------------------------------------------------------------------' >> $JOB_WD/$newuser-$thisdatabase.txt

# For Linux
echo "#" >> $send_emails_script
echo "unix2dos " $newuser-$thisdatabase.txt >> $send_emails_script
echo "zip -P " $ZIPKEY $newuser".zip " $newuser-$thisdatabase".txt" >> $send_emails_script
echo 'mutt -s "New Oracle Database Account on:   ' $thisdatabase '" -a ' $newuser'.zip  -- ' $emailaddress' < ' $newuser-$thisdatabase'.info' >> $send_emails_script
echo "#" >> $send_emails_script
echo "ls -lrt " $newuser-$thisdatabase".txt" >> $send_emails_script
echo "ls -lrt " $newuser-$thisdatabase".txt2" >> $send_emails_script
echo "ls -lrt " $newuser".zip " >> $send_emails_script
echo "ls -lrt " $newuser-$thisdatabase".info" >> $send_emails_script
echo "#" >> $send_emails_script
echo "rm " $newuser-$thisdatabase".txt" >> $send_emails_script
echo "rm " $newuser-$thisdatabase".txt2" >> $send_emails_script
echo "rm " $newuser".zip " >> $send_emails_script
echo "rm " $newuser-$thisdatabase".info" >> $send_emails_script
echo "#" >> $send_emails_script

# For Aix
#echo "#" >> $send_emails_script
#echo "perl -p -e 'chomp; s/$/\\\r\\\n/g;' " $newuser-$thisdatabase".txt > "$newuser-$thisdatabase".tmp_password " >> $send_emails_script
#echo "zip -P " $ZIPKEY $newuser-$thisdatabase".zip " $newuser-$thisdatabase".tmp_password" >> $send_emails_script
#echo "uuencode "$newuser-$thisdatabase".zip "$newuser-$thisdatabase".zip > "$newuser-$thisdatabase".UUzip" >> $send_emails_script
#echo "cat "$newuser-$thisdatabase".info "$newuser-$thisdatabase".UUzip > "$newuser-$thisdatabase".MSG "  >> $send_emails_script
#echo 'mail -s "Your New Oracle Account on ' $thisdatabase ' " ' $emailaddress' < ' $newuser-$thisdatabase'.MSG ' >> $send_emails_script
#echo "#" >> $send_emails_script
#echo "sleep 2" >> $send_emails_script
#echo "#" >> $send_emails_script

echo "========= all done with " $newuser
echo " "
rm $newuser.sh
echo " "
done
#done < $new_users_file
rm $new_users_file
sleep 1

echo "# EOF" >> $send_emails_script
chmod 755 $send_emails_script

echo "Would you like to send these new user accounts NOW  [Y/N] "
read prompt_answer
case $prompt_answer in
     yes|Yes|Y|YES|y)
        echo -e "\n\nSending email(s) now\n\n"
        $send_emails_script > $send_emails_output 2>&1
        ;;
     no|N|n)
        echo -e  "\n\nFile will be saved to be sent out at a later time..."
        echo "Perhaps be launched via crontab at midnight...\n\n"
        ;;
esac
###################################################################################################

echo " "
echo "All done!"
echo " "
echo "Thank You!  Have a nice day!!!  ;=) "
echo " "
##
## M. Luddy
###################################################################################################  
