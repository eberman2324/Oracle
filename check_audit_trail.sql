Doc
*************************************************************************************
Script:         check_audit_trail.sql
Title:          
Author:         Rich Ryan       06/2015
Desc:           This script shows the status of the audit trail purge.

Misc:           This script has successfully executed on 12.1+
*************************************************************************************
#


col parameter_name	format a30
col parameter_value	format a30
col job_frequency	format a30
col job_name            format a30
col audit_trail         format a30
col LAST_ARCHIVE_TS     format a38
col CONTAINER_GUID      format a38


set linesize 340

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/check_audit_trail____&&dbname&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^
select * from  DBA_AUDIT_MGMT_CONFIG_PARAMS;
select * from DBA_AUDIT_MGMT_CLEANUP_JOBS;
select * from DBA_AUDIT_MGMT_LAST_ARCH_TS;
select * from DBA_AUDIT_MGMT_CLEAN_EVENTS;


spool off;
exit;
--
--
