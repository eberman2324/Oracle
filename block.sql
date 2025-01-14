set pages 0
set heading off
set feedback off
select count(*) from v$session
where lockwait is not null
/
exit
