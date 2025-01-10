set echo off pages 0 head off feedback off verify off trimspool on


spool kill_hanganalyzer_session_&1..sql
col name for a30
set linesize 300
col type for a5
col ts for a5

prompt set echo on feed on


select  '-->Kill Time:  ' || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') || '' from v$database;

select '--To be killed:  ' || sql_id ||  ',' || program|| ',' || machine|| '' from v$session where sql_id= '1hvj0yn0zvc1w';


select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' ;' from v$session where sql_id= '1hvj0yn0zvc1w';

spool off



spool KILL_HANG_ANALYZER_SESSION_&1..out 

select chr(10) from dual;

@kill_hanganalyzer_session_&1..sql

spool off

exit