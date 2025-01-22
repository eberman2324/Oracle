#!/bin/bash

# Change Directory
cd /oracle/hrpmaskbackup/data/HEPYMASK

# Files matching these patterns will be sent to Health Edge
filePattern="bkp* c-*"

# sftp user
user=aetna_general

# sftp server
server="207.211.13.68"

# sftp port
port=2223

# Directory on sftp server
remote_directory="/AetnaData"

# Force the script to fail if any file fails to transfer succesfully
fail_if_any_file_fails=1

# Set Current DateTime
DATE=`date +%Y_%m_%d_Time_%H_%M_%S`

# Set Script Log Directory
LOGDIR=/oradb/app/oracle/local/scripts/ftp_backup_to_HE/logs

# Set Log File
LOGOUT=${LOGDIR}/sftp_files_to_he_${DATE}.out

# Set Mail Distribution
#MAILIDS=bermane@aetna.com
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/ftp_backup_to_HE/dba_mail_list`

# Set Work Variable
ERRCNT=0

# Redirect stdout and stderr
exec > >(tee ${LOGOUT}) 2>&1

echo "Starting copy of database backup files at "`date '+%Y-%m-%d %H:%M:%S'`

for file in $( ls ${filePattern}* )
do
    echo
    echo "Sending file ${file} to ${server} at "`date`
    echo -e "cd ${remote_directory}\nput ${file}" | sftp -oPORT=${port} ${user}@${server}
    if [ $? -eq 0 ]
    then
            echo "Successfully transferred file ${file} at "`date`
    else
            if [ $fail_if_any_file_fails ]
            then
                 echo "File ${file} failed to transfer, ending the process at "`date`
                 mailx -s "SFTP File Transfer Process To Health Edge Failed With Error" ${MAILIDS} < ${LOGOUT}
                 chmod 600 ${LOGOUT}
                 exit 1
            else
                 echo "File ${file} failed to transfer, continuing with other files at "`date`
                 ((ERRCNT = $ERRCNT + 1))
           fi
    fi
done

echo
echo
echo "Files Residing on Aetna Server"
echo
ls -l
echo
echo "Files Residing on Health Edge Server"
echo
echo -e "cd ${remote_directory}\nls -l" | sftp -oPORT=${port} ${user}@${server}
echo
echo "End copy of database backup files at "`date '+%Y-%m-%d %H:%M:%S'`
echo

# Send Email
if [ ${ERRCNT} -gt 0 ] ; then
   mailx -s "SFTP File Transfer Process To Health Edge Complete With Errors" ${MAILIDS} < ${LOGOUT}
else
   mailx -s "SFTP File Transfer Process To Health Edge Complete" ${MAILIDS} < ${LOGOUT}
fi

# Move File
if [ -f /oradb/app/oracle/local/scripts/ftp_backup_to_HE/nohup.out ] ; then
   mv /oradb/app/oracle/local/scripts/ftp_backup_to_HE/nohup.out ${LOGDIR}
fi

# Change File Permissions
chmod 600 ${LOGOUT} ${LOGDIR}/nohup.out

