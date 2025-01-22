
set lines 360
set pagesize 30
prompt
prompt ===========================================
prompt   RMAN  Job  Listing
prompt ===========================================
prompt
col time_taken format a12;
col TotalInput format a12;
col TotalOutput format a12;
col Input/s format a12;
col Output/s format a12;
col bkup_type form a10;
col bkup_date form a10;
col device_type form a8;
col status form a10;
col start_time form a20;
col end_time form a20;
col ElapsedTime(m) form 99999999;

SELECT
        -- (SELECT NAME FROM v$database) DB_NAME,
        TO_CHAR(START_TIME,'MM/DD/YYYY')  BKUP_DATE,
        input_type bkup_type,
        OUTPUT_DEVICE_TYPE  DEVICE_TYPE,
        start_time, end_time,
        TIME_TAKEN_DISPLAY time_taken,
        status,
        INPUT_BYTES_DISPLAY "TotalInput",
        OUTPUT_BYTES_DISPLAY "TotalOutput",
        INPUT_BYTES_PER_SEC_DISPLAY  "Input/s",
        OUTPUT_BYTES_PER_SEC_DISPLAY "Output/s",
        ROUND(ELAPSED_SECONDS/60) "ElapsedTime(m)"
FROM
        V$RMAN_BACKUP_JOB_DETAILS
WHERE
        START_TIME >= (SELECT MAX(START_TIME)-1 FROM V$RMAN_BACKUP_JOB_DETAILS)
ORDER BY
        start_time DESC
/

