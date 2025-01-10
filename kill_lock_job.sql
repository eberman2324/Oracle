set echo off pages 0 head off feedback off verify off trimspool on

spool kill_lock_sessions.sql
col name for a30
set linesize 300
col type for a5
col ts for a5

prompt set echo on feed on

select  '-->Kill Time:  ' || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') || '' from v$database;

select '--To be killed:  ' || ses.SQL_ID ||  ',' || ses.machine || '' from gv$lock lk, V$SESSION ses WHERE lk.sid = ses.sid and lk.type = 'UL' and ses.MACHINE like 'xwlhebm%' and lk.CTIME > 84300 and lk.CTIME < 84900;

select 'alter system kill session ''' || ses.sid ||  ',' ||ses.serial#|| ''' immediate;' from gv$lock lk, V$SESSION ses WHERE lk.sid = ses.sid and lk.type = 'UL' and ses.MACHINE like 'xwlhebm%' and lk.CTIME > 84300 and lk.CTIME < 84900;


spool off

spool KILL_LOCK_SESSIONS_&1..out 

select chr(10) from dual;

@kill_lock_sessions.sql

spool off

exit

