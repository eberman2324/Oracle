set echo off pages 0 head off feedback off verify off trimspool on

spool kill_stats_sessions_&1..sql
col name for a30
set linesize 300
col type for a5
col ts for a5

prompt set echo on feed on


select  '-->Kill Time:  ' || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') || '' from v$database;

select '--To be killed:  ' || b.sql_id ||  ',' || b.program|| '' from v$sqltext a,v$session b WHERE a.sql_text like '%SQL Analyze%' and b.program like '%sqlplus%'
AND a.address = b.sql_address
AND    a.hash_value = b.sql_hash_value
and last_call_et > 100;


select 'alter system kill session ''' || b.sid ||  ',' ||b.serial#|| ''' ;' from v$sqltext a,v$session b WHERE a.sql_text like '%SQL Analyze%' and b.program like '%sqlplus%'
AND a.address = b.sql_address
AND    a.hash_value = b.sql_hash_value
and last_call_et > 100;

spool off

spool KILL_STATS_SESSIONS_&1..out

select chr(10) from dual;

@kill_stats_sessions_&1..sql

spool off

exit

