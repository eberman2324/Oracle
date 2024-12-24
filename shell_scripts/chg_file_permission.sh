#!/bin/ksh
BASE=/aetnaprod/backup/sqlloader
DISTRIBUTION=bermane@aetna.com
cd $BASE

#export PATH=$PATH:/usr/bin:/usr/local/bin

#ORACLE_SID=ivpr01
#export ORAENV_ASK=NO
#. oraenv

DATE=`date +%Y%m%d`
#LOGFILE=ivr_hig.log
IVRHIGFILE=/aetnaprod/backup/ivr_hig/Home_Depot_Received_Daily.ttx
#BADFILE=ivr_hig.bad



#sqlldr control=ivr_hig.ctl log=ivr_hig.log userid='"/ as sysdba"'

#ERR=`egrep 'Loader-|ORA-' ${LOGFILE} | grep -c -v "No errors."`

set -x

#gzip ${IVRHIGFILE}
#gzip ${BADFILE}
#gzip ${LOGFILE}

if [ -f "${IVRHIGFILE}" ]; then
    chmod 777 ${IVRHIGFILE}
    mail -s "IVR HIG File Permission changed Successfuly" $DISTRIBUTION <<-EOF
    #EOF
else 
    echo "${IVRHIGFILE} does not exist"
    mail -s "IVR HIG File Permission change Failed" $DISTRIBUTION <<-EOF
fi

#cp -p ${LOGFILE} ${LOGFILE}_${DATE}
#cp -p ${BADFILE} ${BADFILE}_${DATE}




#if [ "$ERR" -eq 0 ]
#then
#   mail -s "IVR HIG File Load Successful" $DISTRIBUTION <<-EOF
#	HIG Transfer Complete with $ERR.
#	EOF
#else
#   mail -s "IVR HIG File Load Failed" $DISTRIBUTION <<-EOF
#	IVR HIG File Load Complete with $ERR.
#	EOF

#fi

exit 0
