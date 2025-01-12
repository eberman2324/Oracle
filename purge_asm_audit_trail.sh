#!/bin/bash
######################################################################################################
#  purge_asm_audit_trail.sh  is executed to purge the ASM instance audit trail  
#
#  usage: $ . purge_asm_audit_trail.sh
#
#
#  Maintenance Log:
#  06/2015      R. Ryan     New Script 
#  09/2015      R. Ryan     Corrected enviromnmental issue when running from cron
#  01/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#####################################################################################################
. ~/.bash_profile
source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs

echo -e '\n'Start ASM audit trail purge  `uname -svrn` at `date` using $0 | tee -a $LOGDIR/purge_asm_audit_tral_$DATEVAR.out
echo 


export ORACLE_SID=+ASM

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------

export ORAENV_ASK=NO
. oraenv | tee -a $LOGDIR/purge_asm_audit_tral_$DATEVAR.out

#------------------------------------------------------------
#  Purge ASM Audit files older then 15 days
#------------------------------------------------------------
echo audit files prior to purge `ls -l $ORACLE_HOME/rdbms/audit/* | wc -l` | tee -a $LOGDIR/purge_asm_audit_tral_$DATEVAR.out

find $ORACLE_HOME/rdbms/audit -name '*.aud' -mtime +15 -exec rm -f {} \;

echo audit files after purge `ls -l $ORACLE_HOME/rdbms/audit/* | wc -l ` | tee -a $LOGDIR/purge_asm_audit_tral_$DATEVAR.out

echo -e '\n'Purge of ASM Audit Trail complete  `uname -svrn` at `date` using $0 | tee -a $LOGDIR/purge_asm_audit_tral_$DATEVAR.out
echo 


exit 0

