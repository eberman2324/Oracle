set echo off pages 0 head off feedback off verify off trimspool on

spool kill_long_running_sessions.sql
col name for a30
set linesize 300
col type for a5
col ts for a5

prompt set echo on feed on
--prompt 



select  '-->Kill Time:  ' || to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') || '' from v$database;

select '--To be killed:  ' || SQL_ID ||  ',' || machine || '' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=1200 and  MACHINE IN (
'xwlheum2p.aetna.com',
'xwlheum3p.aetna.com',
'xwlheum5p.aetna.com',
'xwlheum6p.aetna.com',
'xwlheum4p.aetna.com',
'xwlheum8p.aetna.com',
'xwlheum9p.aetna.com',
'xwlheum10p.aetna.com',
'xwlheum12p.aetna.com',
'xwlheum13p.aetna.com',
'xwlheum14p.aetna.com',
'xwlheum15p.aetna.com',
'xwlheum16p.aetna.com',
'xwlheum17p.aetna.com'
)
UNION
--5400 (90min)
select '--To be killed:  ' || SQL_ID ||  ',' || machine || '' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=5400 and  MACHINE IN (
'xwlheum7p.aetna.com',
'xwlheum11p.aetna.com'
) 
UNION
--600 (10min)
select '--To be killed:  ' || SQL_ID ||  ',' || machine || '' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=600 and
 SQL_ID IN (
'7hp835dg7q5jt',
'6pyhdakcrj19p'
) and
MACHINE IN (
'xhepycpm74p.aetna.com',
'xhepycpm78p.aetna.com',
'xhepycpm79p.aetna.com',
'xhepycpm86p.aetna.com',
'xhepycpm87p.aetna.com',
'xhepycpm88p.aetna.com',
'xhepycpm93p.aetna.com',
'xhepycpm94p.aetna.com'
)
UNION
--60 (1min)
select '--To be killed:  ' || SQL_ID ||  ',' || machine || '' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=60 and
 SQL_ID IN (
'1j2dkd4h6y8hb',
'3p0jg6gf7nnj4',
'8m7u4g1jb6v2y',
'cfqy5d0fffm82',
'47jac3dy09buh',
'85f4ja6ut53c4',
'a2buzgyqj1fmm',
'g8y11vr9judyj',
'7prtgnyxyss6q',
'0gspp52g24zjt',
'391shfbubp4wn',
'c7dwf0j9c3h9m',
'c94vfjj2zv9dx',
'0u2whd1rpnnq6',
'c5dkncph7mjr1',
'cgw1bvpyazhvx',
'dy9j5vvvvzg0j'
);



select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' immediate;' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=1200 and  MACHINE IN (
'xwlheum2p.aetna.com',
'xwlheum3p.aetna.com',
'xwlheum5p.aetna.com',
'xwlheum6p.aetna.com',
'xwlheum4p.aetna.com',
'xwlheum8p.aetna.com',
'xwlheum9p.aetna.com',
'xwlheum10p.aetna.com',
'xwlheum12p.aetna.com',
'xwlheum13p.aetna.com',
'xwlheum14p.aetna.com',
'xwlheum15p.aetna.com',
'xwlheum16p.aetna.com',
'xwlheum17p.aetna.com'
)
UNION
--5400 (90min)
select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' immediate;'  from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=5400 and  MACHINE IN (
'xwlheum7p.aetna.com',
'xwlheum11p.aetna.com'
) 
UNION
--600 (10min)
select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' immediate;' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=600 and
 SQL_ID IN (
'7hp835dg7q5jt',
'6pyhdakcrj19p'
) and
MACHINE IN (
'xhepycpm74p.aetna.com',
'xhepycpm78p.aetna.com',
'xhepycpm79p.aetna.com',
'xhepycpm86p.aetna.com',
'xhepycpm87p.aetna.com',
'xhepycpm88p.aetna.com',
'xhepycpm93p.aetna.com',
'xhepycpm94p.aetna.com'
)
UNION
--60 (1min)
select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''' immediate;' from v$session where status = 'ACTIVE' and SCHEMANAME = 'PROD' and LAST_CALL_ET >=60 and
 SQL_ID IN (
'1j2dkd4h6y8hb',
'3p0jg6gf7nnj4',
'8m7u4g1jb6v2y',
'cfqy5d0fffm82',
'47jac3dy09buh',
'85f4ja6ut53c4',
'a2buzgyqj1fmm',
'g8y11vr9judyj',
'7prtgnyxyss6q',
'0gspp52g24zjt',
'391shfbubp4wn',
'c7dwf0j9c3h9m',
'c94vfjj2zv9dx',
'0u2whd1rpnnq6',
'c5dkncph7mjr1',
'cgw1bvpyazhvx',
'dy9j5vvvvzg0j'
);



spool off

spool KILL_LONG_RUNNING_SESSIONS_&1..out append

select chr(10) from dual;

@kill_long_running_sessions.sql

spool off

exit

