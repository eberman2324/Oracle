

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_audit_trail_tspace__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^




create tablespace audit_space datafile '+DATA_01' size 2048m
/
BEGIN
   dbms_audit_mgmt.set_audit_trail_location(
   audit_trail_type => dbms_audit_mgmt.audit_trail_db_std,
   audit_trail_location_value => 'AUDIT_SPACE');
END;
/
NOAUDIT POLICY ORA_SECURECONFIG
/
audit session by tom
/
audit session by aeaudit
/

