define DBInstance = &1

rem Get environment info. for use in scripts
rem This script should be located in the $SCRIPTS directory
@$SCRIPTS/setup_&&DBInstance

@&&ScriptsFS/aetna/scripts/protected/logit_&DBInstance
rem
rem  This script will setup the environment.
rem 
rem  History:
rem  Date	    Version  Comment            Who
rem
rem  09/27/2001  2.0      Initial version.   MSL 
rem
rem

set linesize 150
set pagesize 1000
set heading off
set feedback off
set verify off
set echo off
column COL2 noprint on

/* MODIFY PATHING / INSTANCE INFORMATION AS NECESSARY */
/*  */

define BackupPath = '&&InstanceFS/&&DBInstance/backups/'
define ColdBackupPath = '&&InstanceFS/&&DBInstance/backups/cold/'
define ChangePathScript = '&&ScriptsFS/aetna/scripts/backup/changepath.sql'
define BackupScript = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/backup001.sql'
define BackupScriptGeneric = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/backup'
define RestoreScript = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/restore.ksh'
define RestoreScriptGeneric = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/restore'
define ColdBackupScriptPath = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/'
define ColdBackupScript = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/cold_backup.ksh'
define ColdRestoreScript = '&&ScriptsFS/aetna/scripts/backup/&&DBInstance/cold_restore.ksh'
define BackupListing = 'backup.lst'

define MailTo = '&&ScriptsFS/aetna/scripts/utility/mailto.ksh'
define EmptyFile = '&&ScriptsFS/aetna/scripts/utility/empty_file'
define MailtoMark = '&&ScriptsFS/aetna/scripts/utility/mark_mail.dat'
define MailToGeneric = '&&ScriptsFS/aetna/scripts/utility/mailto_'

/* Modify the SELECT statement if you wish to change the output path */
/* For single path output put "rem" in front of the following 4 lines */
rem spool &&ChangePathScript
rem select 'define BackupPath=', '&&BackupPath' || substr(TO_CHAR(sysdate,'DAY'),1,3) || '/' from dual;
rem spool off
rem @&&ChangePathScript

