set echo off pages 0 head off feedback off verify off trimspool on


spool kill_S012030.sql
col name for a30
set linesize 300
col type for a5
col ts for a5

prompt set echo on feed on


select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' ;' from v$session where username='S012030';

spool off



spool kill_S012030.out 

select chr(10) from dual;

@kill_S012030.sql

spool off

exit

