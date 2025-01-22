Doc
*************************************************************************************
Script:         disable_unified_audit_policies.sql
Title:          
Author:         Rich Ryan       04/2016
Desc:           This script disables unified audit policies and purges the unified audit trail.

Misc:           This script has successfully executed on 12.1+
*************************************************************************************
#



set linesize 340

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/disable_unified_audit_policies____&&dbname&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


noaudit policy ORA_LOGON_FAILURES;
noaudit policy ORA_SECURECONFIG;
set head off
select 'Unified Audit Count Before Purge: '||count(*) from unified_audit_trail;

BEGIN
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
   AUDIT_TRAIL_TYPE           =>  DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
   USE_LAST_ARCH_TIMESTAMP    =>  FALSE);
END;
/

select 'Unified Audit Count After Purge: ' || count(*) from unified_audit_trail;

spool off;
exit;
--
--
