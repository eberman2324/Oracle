#!/bin/ksh

# fn      : chg_unix_pwd.ksh
# purpose : Change Password For Unix Login Account Oracle

#Set Oracle Home Directory
OHD=/orahome/wkab01/app/oracle

#Set Directory
CURDIR=/orahome/wkab01/aetna/scripts/misc

#Set Email Distribution List
#MAILIDS=`paste -s /u01/app/oracle/aetna/mail/dba_mail_list`
MAILIDS=bermanE@aetna.com 
#Change Directory
cd $CURDIR

#Get Day Of The Month
integer CURRDAY=`date '+%d'`

#If Not First Sunday Of The Month 
#if [ ${CURRDAY} -gt 7 ]; then
#   #mailx -s "Oracle Password Not Due For a Change Yet on `date`" ${MAILIDS} < /dev/null
#   mailx -s "Oracle Password Not Due For a Change Yet on `date`" bermane@aetna.com < /dev/null
#   exit 0
#fi

#Define Script Work Files
_outtmp=${CURDIR}/.chg_unix_pw2
_outtmp2=${CURDIR}/.chg_unix_pw_history
_outtmp3=${CURDIR}/.chg_unix_server
_outtmp4=${OHD}/.oracle_new.pw

#Set Current Password
CURRENTPW=`cat ${OHD}/.oracle.pw`

#New Password Must be at least eight characters
#Two numeric characters required
NEWPW=`${CURDIR}/get_random_key.ksh CNULNAAA $CURRENTPW`

#Remove Files From Last Run
rm -f ${_outtmp} ${_outtmp3} ${_outtmp4}

#Create Files
touch ${_outtmp} ${_outtmp3}

#Create Temporary New Password File To Be Used By Remote Servers
echo ${NEWPW} > ${_outtmp4}

#Set File Permissions
chmod 640 ${_outtmp} ${_outtmp2} ${_outtmp3} ${_outtmp4}

#Set Zeke Return Code
integer ZekeRtnCode=0

#Loop Through All Servers Requiring Password Change
cat $CURDIR/oracle_servers.txt | while read srvname
do
if test -n "${srvname}"
then


#SSH To Unix Server
ssh -n ${srvname} ${CURDIR}/chg_password.ksh > ${_outtmp}



RC=`grep -c "3004-" ${_outtmp}`

if [ $RC -eq 0 ]; then
	echo "Password successfully changed on server ${srvname} at "`date` >> ${_outtmp3}
	echo "Password successfully changed on server ${srvname} at "`date` >> ${_outtmp2}
   #echo "Password successfully changed on server ${srvname}" >> ${_outtmp3}
else
   echo "Password not changed on server ${srvname}" >> ${_outtmp3}
   cat ${_outtmp} >> ${_outtmp2}
   ZekeRtnCode=1
fi
fi
done

#End Loop

# If password successfully changed on spnode45 - update hidden file
RC=`grep -c "Password successfully changed on server aetnaprod" ${_outtmp3}`
if [ $RC -eq 1 ]; then
     echo ${NEWPW} > ${OHD}/.oracle.pw
     if [ $? -ne 0 ] ; then
        echo "Error updating file .oracle.pw on server aetnaprod after password change" >> ${_outtmp3}
     else
        chmod 640 ${OHD}/.oracle.pw
     fi
fi

# If password successfully changed on xxxxx - update hidden file
#RC=`grep -c "Password successfully changed on server xxxxx" ${_outtmp3}`
#if [ $RC -eq 1 ]; then
#     scp -p ${OHD}/.oracle_new.pw xxxxx:${OHD}/.oracle.pw
#     if [ $? -ne 0 ] ; then
#        echo "Error copying file .oracle_new.pw to server XXXXX after password change" >> ${_outtmp3}
#        ZekeRtnCode=1
#     fi
#fi

#Send Email Notification
mailx -s "Oracle Password Change Run on `date`" bermane@aetna.com swaffordM@aetna.com < ${_outtmp3} 

#Remove Temp PassWord File If No Errors Encountered
if [ ${ZekeRtnCode} -eq 0 ]; then
    rm ${_outtmp4}
fi

#Exit Script
exit $ZekeRtnCode

