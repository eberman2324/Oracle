alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
select state from V$LOGSTDBY_STATE;
select APPLIED_TIME, applied_scn, LATEST_TIME, latest_scn from v$logstdby_progress;

