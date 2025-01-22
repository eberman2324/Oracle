export ORACLE_HOME=$1
/usr/bin/find $ORACLE_HOME/rdbms/audit -name \*.aud -mtime +7 -exec rm -f {} \;
