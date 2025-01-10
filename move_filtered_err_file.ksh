#!/bin/ksh

# Rename filtered_err file for scan_oracle check to
# prevent "wordlist too large" error from occurring
# for all databases that are currently running

#Define Script Variable
integer RC=0

OUTDIR="/oradb/app/oracle/local/scripts/monitor"
ORACLE_BASE=/oradb/app/oracle



OUTFILE=${OUTDIR}/move_ferr.out
ERRFILE=${OUTDIR}/move_ferr.err
CURRDATE="`date +%Y%m%d_%T`"

#Set Email Distribution List

#new standard
MAILIDS=`paste -s /oradb/app/oracle/local/scripts/mail/dba_mail_list`


#Create Work Files
touch $OUTFILE $ERRFILE

if [ $1 ]
then   
     # Set DataBase Name
     DBName=`echo $1 |tr "[:lower:]" "[:upper:]"`   
     ps -ef | grep pmon | grep -v grep > pmon.out
     ps -ef| grep ${DBName} pmon.out |awk '{ print $8 }' | tail -c 10 > instname.out
     DBName=`cat instname.out`
     export ORAENV_ASK=NO
     ORACLE_SID=${DBName}
     DB=$1
     CLUSTERNAME=`cat clustername`

       

fi

export DB_UNIQUE_NAME=${DB}_${CLUSTERNAME} 
#export BDUMP=${ORACLE_BASE}/diag/rdbms/${DB_UNIQUE_NAME}/${ORACLE_SID} | tr "[:upper:]" "[:lower:]"/trace;
#export UDUMP=${ORACLE_BASE}/diag/rdbms/${DB_UNIQUE_NAME}/${ORACLE_SID} | tr "[:upper:]" "[:lower:]"/trace;



if [ -f ${BDUMP}/filtered_err ] ; then
         echo "Renaming file ${BDUMP}/filtered_err to ${BDUMP}/filtered_err_${CURRDATE}" >> ${OUTFILE}
         mv ${BDUMP}/filtered_err ${BDUMP}/filtered_err_${CURRDATE}
         if [ $? -ne 0 ]; then
            echo "Error Renaming file ${BDUMP}/filtered_err to ${BDUMP}/filtered_err_${CURRDATE}" >> ${ERRFILE}
            RC=1
         fi
fi

if [ $RC -eq 0 ]; then
   mailx -s "Rename Filtered Err File Script Successful" ${MAILIDS} < $OUTFILE
else
   mailx -s "Rename Filtered Err File Script Encountered Errors" ${MAILIDS} < $ERRFILE
fi

rm -f $OUTFILE $ERRFILE
