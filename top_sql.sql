-----------Top 10 sql -------------------
--V$SQLAREA lists statistics on shared SQL area and contains one row per SQL string.
-- It provides statistics on SQL statements that are in memory, parsed, and ready for execution.
-- ***THIS JUST WHAT SITTING IN MEMORY,NOT WHAT BEING EXECUTED NOW ****---
SELECT *
FROM   (SELECT Substr(a.sql_text,1,50) sql_text,
               Trunc(a.disk_reads/Decode(a.executions,0,1,a.executions)) reads_per_execution, 
               a.buffer_gets, 
               a.disk_reads, 
               a.executions, 
               a.sorts,
               a.address
        FROM   v$sqlarea a
        ORDER BY 2 DESC)
WHERE  rownum <= 10;


select * from v$sqlarea;
---------Most CPU Intensive Sessions---------------------------

select ss.sid,se.command,ss.value CPU ,se.username,se.program 
from v$sesstat ss, v$session se
where ss.statistic# in 
(select statistic# 
from v$statname 
where name = 'CPU used by this session')
and se.sid=ss.sid 
and ss.sid>6
order by CPU desc;

----Put SID to get SQL and SPID (OS Process ID)--------
select s.sid,p.spid, event, wait_time, w.seq#, q.sql_text
from v$session_wait w, v$session s, v$process p, v$sqlarea q
where s.paddr=p.addr and
s.sid=625 and
s.sql_address=q.address;

-------Put SPID (OS Process ID) to get SQL and SID--------
select s.sid,p.spid, event, wait_time, w.seq#, q.sql_text
from v$session_wait w, v$session s, v$process p, v$sqlarea q
where s.paddr=p.addr and
p.spid=2584776 and
s.sql_address=q.address;


select * from v$process


-----Latch contention--------------------------------
select * from v$latch;
select *  from v$session_wait where event='latch free'; --if records this mean we have contention

---Here's what I did to clear out the old sessions 
--that were spinning on latches on causing the CPU to max out.
select 'alter system kill session ''' || sid || ',' || serial# || ''';' last_call_et 
from v$session s where s.last_call_et > 600 and sid 
in (select sid from v$session_wait where event='latch free');

select * from v$session where status= 'KILLED'

select * from v$session where sid = 506