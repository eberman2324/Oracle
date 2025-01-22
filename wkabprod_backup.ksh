#!/bin/ksh
PATH=$PATH:/usr/local/bin

export ORAENV_ASK=NO
export ORACLE_SID=wkabprod

. oraenv

cd /orahome/wkab01/aetna/scripts/backup

# Backup DataBase
rman nocatalog << EOF
 connect target /
 run
 {
  BACKUP CHECK LOGICAL DATABASE PLUS ARCHIVELOG;
  BACKUP ARCHIVELOG ALL;
 }
 create restore point "wkabprod_20210216";
 run
 {
  ALTER SYSTEM ARCHIVE LOG CURRENT;
  BACKUP ARCHIVELOG ALL;
 }
EOF

echo "------------ Backup Complete ------------------"


chmod 777 wkabprod_backup.ksh
