select start_time, end_time, input_type, elapsed_seconds, input_bytes_per_sec from V$RMAN_BACKUP_JOB_DETAILS where input_type='DB FULL'
/
