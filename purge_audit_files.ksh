
export DBName=$1
/usr/bin/find /orahome/u01/app/oracle/admin/$DBName/adump -name \*.aud -mtime +3 -exec rm -f {} \;


