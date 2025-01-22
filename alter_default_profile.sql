
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/alter_default_profile___&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^




ALTER PROFILE "DEFAULT" LIMIT PASSWORD_LIFE_TIME UNLIMITED
PASSWORD_VERIFY_FUNCTION ai_password_validate_v2
/

ALTER PROFILE "DEFAULT" LIMIT PASSWORD_REUSE_MAX 24
PASSWORD_REUSE_TIME 365
/

