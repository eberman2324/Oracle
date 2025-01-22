--
-- This script compares following two
--            DB CPU as percentage of DB Time in old environment
--            DB CPU as percentage of DB Time in new environment
--    New environment is identified by dbid in v$database
--    Old environment is identified by dbid not in v$database. 
--    Old dbid is for AWR data exported from source and imported into target  
--    Comparison is done for all activity during available periods (old & new)
--    


WITH db_time_old
     AS (SELECT ROUND ( (MAX (VALUE) - MIN (VALUE)) / (1000000 * 60)) db_time
           FROM DBA_HIST_SYS_time_model a, v$database c
          WHERE a.stat_name = 'DB time' AND a.dbid != c.dbid),
     db_cpu_old
     AS (SELECT ROUND ( (MAX (VALUE) - MIN (VALUE)) / (1000000 * 60)) db_cpu
           FROM DBA_HIST_SYS_time_model a, v$database c
          WHERE a.stat_name = 'DB CPU' AND a.dbid != c.dbid),
     db_time_new
     AS (SELECT ROUND ( (MAX (VALUE) - MIN (VALUE)) / (1000000 * 60)) db_time
           FROM DBA_HIST_SYS_time_model a, v$database c
          WHERE a.stat_name = 'DB time' AND a.dbid = c.dbid),
     db_cpu_new
     AS (SELECT ROUND ( (MAX (VALUE) - MIN (VALUE)) / (1000000 * 60)) db_cpu
           FROM DBA_HIST_SYS_time_model a, v$database c
          WHERE a.stat_name = 'DB CPU' AND a.dbid = c.dbid)
SELECT ROUND ( (b.db_cpu * 100) / a.db_time) old_db_cpu_as_perc_of_db_time,
       ROUND ( (d.db_cpu * 100) / c.db_time) new_db_cpu_as_perc_of_db_time
  FROM db_time_old a,
       db_cpu_old b,
       db_time_new c,
       db_cpu_new d
