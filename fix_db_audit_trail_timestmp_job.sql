BEGIN
 DBMS_SCHEDULER.DROP_JOB (
          job_name => 'DAILY_DB_AUDIT_ARCHIVE_TIMESTP'
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

