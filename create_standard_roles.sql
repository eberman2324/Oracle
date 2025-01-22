

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_standard_roles__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


CREATE ROLE APP_DATA_MOD_ROLE NOT IDENTIFIED
/
GRANT CREATE SESSION TO APP_DATA_MOD_ROLE
/
CREATE ROLE APP_DEVELOPER_ROLE NOT IDENTIFIED
/
GRANT CREATE SESSION TO APP_DEVELOPER_ROLE
/
CREATE ROLE APP_USER_ROLE NOT IDENTIFIED
/
GRANT CREATE SESSION TO APP_USER_ROLE
/
