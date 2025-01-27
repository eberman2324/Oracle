export ORACLE_SID=$1
export DIAGNOSTIC_DEST=$2
find $DIAGNOSTIC_DEST/diag/rdbms/"$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')"/$ORACLE_SID/trace/ -depth -type f -mtime +31 -exec ls -altr {} \;
find $DIAGNOSTIC_DEST/diag/rdbms/"$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')"/$ORACLE_SID/trace/ -depth -type f -mtime +31 -exec rm -f {} \;
