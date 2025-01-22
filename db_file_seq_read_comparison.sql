--
-- This script compares following two
--            Average db_file_sequential_read time in old environment
--            Average db_file_sequential_read time in new environment
--    Comparison is done for all activity during available periods (old & new)
--    New environment is identified by dbid in v$database
--    Old environment is identified by dbid not in v$database. 
--    Old dbid is for AWR data exported from source and imported into target  
--   
--    


WITH db_sequential_old
     AS (SELECT ROUND (
                     (MAX (a.time_waited_micro) - MIN (b.time_waited_micro))
                   / ( (MAX (a.total_waits) - MIN (b.total_waits)) * 1000),
                   1)
                   old_avg_read_time_seq_millsec
           FROM dba_hist_system_event a,
                dba_hist_system_event b,
                v$database c
          WHERE     a.event_name = 'db file sequential read'
                AND b.event_name = 'db file sequential read'
                AND (a.total_waits - b.total_waits) > 0
                AND b.snap_id = a.snap_id - 1
                AND a.dbid != c.dbid
                AND b.dbid != c.dbid
                AND a.dbid = b.dbid),
      db_sequential_new
     AS (SELECT ROUND (
                     (MAX (a.time_waited_micro) - MIN (b.time_waited_micro))
                   / ( (MAX (a.total_waits) - MIN (b.total_waits)) * 1000),
                   1)
                   new_avg_read_time_seq_millsec
           FROM dba_hist_system_event a,
                dba_hist_system_event b,
                v$database c
          WHERE     a.event_name = 'db file sequential read'
                AND b.event_name = 'db file sequential read'
                AND (a.total_waits - b.total_waits) > 0
                AND b.snap_id = a.snap_id - 1
                AND a.dbid = c.dbid
                AND b.dbid = c.dbid
                AND a.dbid = b.dbid)
SELECT *
  FROM db_sequential_old, db_sequential_new
