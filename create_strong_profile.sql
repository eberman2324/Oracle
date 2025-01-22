

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_strong_profile__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^



CREATE PROFILE STRONG
    LIMIT SESSIONS_PER_USER         DEFAULT
          CPU_PER_SESSION           DEFAULT
          CPU_PER_CALL              DEFAULT
          CONNECT_TIME              DEFAULT
          IDLE_TIME                 DEFAULT
          LOGICAL_READS_PER_SESSION DEFAULT
          LOGICAL_READS_PER_CALL    DEFAULT
          COMPOSITE_LIMIT           DEFAULT
          PRIVATE_SGA               DEFAULT
          FAILED_LOGIN_ATTEMPTS     5
          PASSWORD_LIFE_TIME        90
          PASSWORD_REUSE_TIME       390
          PASSWORD_REUSE_MAX        24
          PASSWORD_LOCK_TIME        .0034
          PASSWORD_GRACE_TIME       10
          PASSWORD_VERIFY_FUNCTION  AI_PASSWORD_VALIDATE_V2
/
