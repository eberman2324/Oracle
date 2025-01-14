set verify off feedback off echo off term off
set trimspool on trimout on linesize 200
set pagesize 999

col username for a10
col machine for a30
col event for a64

spool &1 APPEND

select name as "DataBase", to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "CurrDate" from v$database;

prompt
prompt Sessions By Event

select event,count(*)
from v$session
where audsid != userenv('sessionid')
group by event
order by 2;

prompt
prompt Sessions By Host

select machine,count(*)
from v$session
where audsid != userenv('sessionid')
group by machine
order by 2;

prompt
prompt Sessions By User

select username,count(*)
from v$session
where audsid != userenv('sessionid')
group by username
order by 2;

prompt
prompt Count Of Sessions By Host With a Logon In The Last Minute

select machine,count(*)
from v$session
where logon_time > sysdate - 1/(24*60)
and   audsid != userenv('sessionid')
group by machine
order by 2;

prompt
prompt Count Of Sessions With a Logon In The Last Minute

select count(*)
from v$session
where logon_time > sysdate - 1/(24*60)
and   audsid != userenv('sessionid');

prompt
prompt Count Of Processes

--select count(*)
--from v$process;
select 'Total Count Of Processes - ' ||count(*) as "Total Process Count" from v$process;

set pagesize 0

select substr(rpad(dummy,123,'-'),2) from dual;
select substr(rpad(dummy,123,'-'),2) from dual;

