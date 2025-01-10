#!/bin/sh

# Check For Input DataBase Name
if [ ${#} -ne 1 ]
then
 echo
 echo "Input DataBase Name Not Passed - Script Aborting"
 exit 1
fi

# Get Input DataBase Name
DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`

################################################################################################

ps -ef | grep pmon | grep -v grep > pmon.out
ps -ef| grep ${DBName} pmon.out |awk '{ print $8 }' | tail -c 10 > instname.out
DBName=`cat instname.out`

###################################################################################################



# Set Email Distribution
#MAILIDS=bermane@aetna.com
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/monitor/rman/dba_mail_list`

# Confirm Heart Beat Script Not Commented in Cron
HBCNT=`crontab -l |grep "^#" |grep heartbeat|grep ${DBName}|wc -l`
if [ ${HBCNT} -eq 1 ] ; then
  mailx -s "Heartbeat Script For DataBase ${DBName} Not Active In Cron" ${MAILIDS} < /dev/null
fi

