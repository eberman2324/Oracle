
export ORACLE_SID=$1
/usr/bin/find /orabin/admin/$ORACLE_SID/adump -name \*.aud -mtime +31 -exec rm -f {} \;
