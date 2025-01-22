export ORACLE_SID=$1
cd /orahome/u01/app/oracle/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace
cp alert_$ORACLE_SID.log.father alert_$ORACLE_SID.log.gfather
mv alert_$ORACLE_SID.log alert_$ORACLE_SID.log.father
