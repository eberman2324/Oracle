set echo off pages 0 head off feedback off verify off trimspool on
whenever sqlerror exit failure;
spool py_long_runners_report.sql
col name for a100
set linesize 75
col type for a5
col ts for a5
set wrap off

prompt set echo on feed on


--prompt 



--select  '-->Current Time:  ' || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') || '' from v$database;




--select '--Long running sessions for:  ' || SQL_ID ||  ''  from v$session where status = 'ACTIVE' and SCHEMANAME NOT IN ( 'SYS','DBSNMP') AND LOGON_TIME < = sysdate - 6/24 ORDER BY LOGON_TIME;
--select '--Long running sessions for:  ' || SQL_ID ||  ',' || SCHEMANAME || ''  from v$session where status = 'ACTIVE' and SCHEMANAME NOT IN ( 'SYS','DBSNMP') AND LAST_CALL_ET >=7200 ORDER BY LOGON_TIME;
--select SQL_ID, SCHEMANAME from v$session where status = 'ACTIVE' and SCHEMANAME NOT IN ( 'SYS','DBSNMP') AND LAST_CALL_ET >=7200 ORDER BY LOGON_TIME;
select SQL_ID, SCHEMANAME from v$session where  SCHEMANAME NOT IN ( 'SYS','DBSNMP') AND LAST_CALL_ET >=7200 and SQL_ID IS NOT NULL  and EVENT = 'SQL*Net message from client' ORDER BY LOGON_TIME;
spool off

spool PY_LONG_RUNNING_SESSIONS_&1..out

select chr(10) from dual;

@py_long_runners_report.sql

spool off

exit