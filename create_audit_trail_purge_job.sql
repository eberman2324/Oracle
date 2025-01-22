
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_audit_trail_purge__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

BEGIN
  DBMS_AUDIT_MGMT.INIT_CLEANUP(
    AUDIT_TRAIL_TYPE => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
    DEFAULT_CLEANUP_INTERVAL => 240 /*hours*/
  );
END;
/

BEGIN
  DBMS_AUDIT_MGMT.INIT_CLEANUP(
    AUDIT_TRAIL_TYPE => DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,
    DEFAULT_CLEANUP_INTERVAL => 240 /*hours*/
  );
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name   => 'DAILY_DB_AUDIT_ARCHIVE_TIMESTP',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE => 
                   DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD, LAST_ARCHIVE_TIME => sysdate-30); END;',
    start_date => sysdate, 
    repeat_interval => 'FREQ=HOURLY;INTERVAL=24', 
    enabled    =>  TRUE,
    comments   => 'Create an archive timestamp'
  );
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name   => 'DAILY_OS_AUDIT_ARCHIVE_TIMESTP',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(AUDIT_TRAIL_TYPE => 
                   DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,LAST_ARCHIVE_TIME => sysdate-30); END;', 
    start_date => sysdate, 
    repeat_interval => 'FREQ=HOURLY;INTERVAL=24', 
    enabled    =>  TRUE,
    comments   => 'Create an archive timestamp'
  );
END;
/

BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    AUDIT_TRAIL_TYPE           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
    AUDIT_TRAIL_PURGE_INTERVAL => 24 /* hours */,
    AUDIT_TRAIL_PURGE_NAME     => 'Daily_DB_Audit_Purge_Job',
    USE_LAST_ARCH_TIMESTAMP    => TRUE
  );
END;
/


BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    AUDIT_TRAIL_TYPE           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_OS,
    AUDIT_TRAIL_PURGE_INTERVAL => 24 /* hours */,
    AUDIT_TRAIL_PURGE_NAME     => 'Daily_OS_Audit_Purge_Job',
    USE_LAST_ARCH_TIMESTAMP    => TRUE
  );
END;
/


