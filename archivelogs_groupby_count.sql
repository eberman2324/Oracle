select count(*) as LOGS_GENERATED, to_char(next_time,'mm/dd/yyyy HH24') AS HOUR, SUM(BLOCKS * BLOCK_SIZE) /1024/1024/1024 SIZE_GB
from v$archived_log where to_char(next_time,'mm/dd/yyyy') = '08/27/2024'
group by to_char(next_time,'mm/dd/yyyy HH24')
ORDER BY HOUR;

--How much archive log space used in a day: 
select trunc(COMPLETION_TIME) TIME, ROUND(SUM(BLOCKS * BLOCK_SIZE)/1024/1024/1024) SIZE_GB from V$ARCHIVED_LOG group by trunc (COMPLETION_TIME) order by 1 desc;

select * from  v$archived_log  order by next_time desc

select count(*) * 100000 from v$archived_log where to_char(next_time,'mm/dd/yyyy') = '12/20/2009'
-- Get actual size of archive file on server and times full day count.
select 91734016 * 2159 from dual

select trunc(COMPLETION_TIME) TIME, SUM(BLOCKS * BLOCK_SIZE)/1024/1024 SIZE_MB from V$ARCHIVED_LOG group by trunc (COMPLETION_TIME) order by 1;
select trunc(COMPLETION_TIME) TIME, SUM(BLOCKS * BLOCK_SIZE)/1024/1024 SIZE_MB from V$ARCHIVED_LOG where to_char(next_time,'mm/dd/yyyy') = '12/23/2018'
 group by trunc (COMPLETION_TIME) order by 1;
 
 select sequence#,completion_time, next_change# as scn 
         from v$archived_log 
            order by completion_time desc;
            
            select sequence#,COMPLETION_TIME TIME from V$ARCHIVED_LOG where to_char(next_time,'mm/dd/yyyy') = '08/29/2023' order by 2 desc