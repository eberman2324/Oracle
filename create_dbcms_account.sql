
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_dbcms_account__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

-- Create the profile used by the DBCMS acoount.
CREATE PROFILE TRUSTED_ID_NO_EXPIRE LIMIT
  SESSIONS_PER_USER DEFAULT
  CPU_PER_SESSION DEFAULT
  CPU_PER_CALL DEFAULT
  CONNECT_TIME DEFAULT
  IDLE_TIME DEFAULT
  LOGICAL_READS_PER_SESSION DEFAULT
  LOGICAL_READS_PER_CALL DEFAULT
  COMPOSITE_LIMIT DEFAULT
  PRIVATE_SGA DEFAULT
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LIFE_TIME UNLIMITED
  PASSWORD_REUSE_TIME 365
  PASSWORD_REUSE_MAX 6
  PASSWORD_LOCK_TIME 1
  PASSWORD_GRACE_TIME UNLIMITED
  PASSWORD_VERIFY_FUNCTION DEFAULT;
  
-- Create the ICR AUDIT role
CREATE ROLE ICR_AUDIT NOT IDENTIFIED;

-- System privileges granted to ICR_AUDIT
GRANT CREATE SESSION TO ICR_AUDIT;
GRANT SELECT ANY DICTIONARY TO ICR_AUDIT;

-- Roles granted to ICR_AUDIT
GRANT SELECT_CATALOG_ROLE TO ICR_AUDIT;

grant select on sys.user$ to icr_audit;

-- Grantees of ICR_AUDIT
GRANT ICR_AUDIT TO SYSTEM WITH ADMIN OPTION;  

-- Create the DBCMS ICR Audit user
CREATE USER DBCMS
  IDENTIFIED BY VALUES 'BBEE1F9B3A94B3CF'
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE TRUSTED_ID_NO_EXPIRE
  ACCOUNT UNLOCK;
  -- 1 Role for DBCMS 
  GRANT ICR_AUDIT TO DBCMS;
  ALTER USER DBCMS DEFAULT ROLE ALL;
  -- 1 Tablespace Quota for DBCMS 
  ALTER USER DBCMS QUOTA UNLIMITED ON USERS;
  -- 2 Object Privileges for DBCMS which can not be granted at the role level.
  -- Permits on these objects do not work via role based privs
    GRANT SELECT ON SYS.DBA_OBJECTS TO DBCMS;
    GRANT SELECT ON SYS.DEPENDENCY$ TO DBCMS;
