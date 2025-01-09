set pages 0
set heading off
set feedback off
select count(*) from v$session
/
exit



select module, count(*) from v$session group by module order by 2;
select machine, count(*) from v$session group by machine order by 2;
select program, count(*) from v$session group by program order by 2;


select count(*) from v$session where machine = 'fms_rebuild'
select count(*) from v$session where machine = 'lakws00034'
select *  from v$session where machine = 'lakws00035'
select SID,USERNAME, SCHEMANAME,OSUSER, MACHINE, PROGRAM,MODULE,LOGON_TIME from v$session where machine = 'gsovmintjava01'
order by 1


select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE from v$session GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC