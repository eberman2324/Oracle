--
-- This script compares following two
--            Host CPU percentage in old environment
--            Host CPU percentage in new environment
--   New environment is identified by dbid in v$database
--   Old environment is identified by dbid not in v$database. 
--   Old dbid is for AWR data exported from source and imported into target  
--   Comparison is done for all activity during available periods (old & new)
--    


WITH old_host_cpu
     AS (SELECT ROUND (AVG (average)) AS Host_CPU_Percentage_old
           FROM DBA_HIST_SYSMETRIC_SUMMARY a, v$database b
          WHERE metric_name = 'Host CPU Utilization (%)' AND a.DBID != b.dbid),
     new_host_cpu
     AS (SELECT ROUND (AVG (average)) AS Host_CPU_Percentage_new
           FROM DBA_HIST_SYSMETRIC_SUMMARY a, v$database b
          WHERE metric_name = 'Host CPU Utilization (%)' AND a.DBID = b.dbid)
SELECT *
  FROM old_host_cpu, new_host_cpu
