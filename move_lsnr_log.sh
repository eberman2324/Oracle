export ORACLE_SID=$1
export ORACLE_BASE=$2
cd $ORACLE_BASE/diag/tnslsnr/aetnaprod/"$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')"/trace
cp "$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')".log.father "$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')".log.gfather
mv "$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')".log "$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')".log.father

