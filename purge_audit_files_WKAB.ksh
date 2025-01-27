export AUDIT_DEST=/workability/wkabprod/oracle/admin/adump
/usr/bin/find $AUDIT_DEST -name \*.aud -mtime +7 -exec rm -f {} \;
