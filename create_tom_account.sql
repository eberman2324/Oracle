
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_tom_account__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^



CREATE USER TOM IDENTIFIED BY VALUES '3141BFFD0D91699D' 
    DEFAULT TABLESPACE USERS 
    TEMPORARY TABLESPACE TEMP 
    PROFILE TRUSTED_ID_NO_EXPIRE
    ACCOUNT UNLOCK 
/ 
GRANT "CONNECT" TO TOM 
/ 
ALTER USER TOM DEFAULT ROLE "CONNECT" 
/ 
GRANT SELECT ON SYS.V_$SYSTEM_PARAMETER TO TOM 
/ 
GRANT SELECT ON SYS.V_$PWFILE_USERS TO TOM 
/ 
GRANT SELECT ON SYS.DBA_ROLES TO TOM 
/ 
GRANT SELECT ON SYS.DBA_USERS TO TOM 
/ 
GRANT SELECT ON SYS.DBA_ROLE_PRIVS TO TOM 
/ 
GRANT SELECT ON SYS.DBA_SYS_PRIVS TO TOM 
/ 
GRANT SELECT ON SYS.DBA_PROFILES TO TOM 
/ 
grant select on         sys.defrole$    to TOM
/
grant select on         sys.user$       to TOM
/
grant select on         sys.sysauth$    to TOM
/
GRANT ALTER ANY ROLE TO TOM 
/ 
GRANT ALTER PROFILE TO TOM 
/ 
GRANT ALTER USER TO TOM 
/ 
GRANT CREATE PROFILE TO TOM 
/ 
GRANT CREATE ROLE TO TOM 
/ 
GRANT CREATE SESSION TO TOM 
/ 
GRANT CREATE USER TO TOM 
/ 
GRANT DROP ANY ROLE TO TOM 
/ 
GRANT DROP PROFILE TO TOM 
/ 
GRANT DROP USER TO TOM 
/ 
GRANT GRANT ANY PRIVILEGE TO TOM 
/ 
GRANT GRANT ANY ROLE TO TOM 
/ 
