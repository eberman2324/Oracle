#!/bin/ksh


# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/monitor/orasupp"

# Change Directory
cd ${SCRDIR}/logs



# Set Email Distribution
MAILIDS=`paste -s ${SCRDIR}/cust_mail_list`


# Set Current Date
DATE=`date +%Y-%m-%d`

# Set Script OutPut File
FN=get_session_info_${DATE}.out


#mailx -s "Daily Sessin Info Report" ${MAILIDS} < ${FN}

#mailx  ${FN} -s "Daily Sessin Info Report" ${MAILIDS}

mailx -a ${FN} -s "Daily Session Info Report - HEPYSTS" ${MAILIDS} < /dev/null


