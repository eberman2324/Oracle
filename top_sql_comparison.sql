--
-- This script compares following two
--            Top SQL in old environment
--            Top SQL in new environment
--    Top SQL is defined as top 10 SQL responsible for most buffer gets
--    Comparison is done for all activity during available periods (old & new)
--    New environment is identified by dbid in v$database
--    Old environment is identified by dbid not in v$database. 
--    Old dbid is for AWR data exported from source and imported into target  
--   
--    


WITH old_sql_stats
     AS (     SELECT 'Old' old_or_new,
                     sql_id,
                     SUM (executions_delta) total_exec,
                     ROUND (SUM (buffer_gets_delta) / SUM (executions_delta))
                        buffer_per_exec,
                     ROUND (SUM (cpu_time_delta) / SUM (executions_delta))
                        cpu_per_exec,
                     ROUND (SUM (iowait_delta) / SUM (executions_delta))
                        iowat_per_exec,
                     ROUND (SUM (elapsed_time_delta) / SUM (executions_delta))
                        elapsed_per_exec
                FROM dba_hist_sqlstat a, v$database b
               WHERE a.dbid != b.dbid
              HAVING SUM (executions_delta) > 0
            GROUP BY sql_id
            ORDER BY SUM (buffer_gets_delta) DESC
         FETCH FIRST 10 ROWS ONLY),
     new_sql_stats
     AS (     SELECT 'New' old_or_new,
                     sql_id,
                     SUM (executions_delta) total_exec,
                     ROUND (SUM (buffer_gets_delta) / SUM (executions_delta))
                        buffer_per_exec,
                     ROUND (SUM (cpu_time_delta) / SUM (executions_delta))
                        cpu_per_exec,
                     ROUND (SUM (iowait_delta) / SUM (executions_delta))
                        iowat_per_exec,
                     ROUND (SUM (elapsed_time_delta) / SUM (executions_delta))
                        elapsed_per_exec
                FROM dba_hist_sqlstat a, v$database b
               WHERE a.dbid = b.dbid
              HAVING SUM (executions_delta) > 0
            GROUP BY sql_id
            ORDER BY SUM (buffer_gets_delta) DESC
         FETCH FIRST 10 ROWS ONLY)
SELECT * FROM old_sql_stats
UNION
SELECT * FROM new_sql_stats
ORDER BY 2, 1
