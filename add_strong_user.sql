define NEWUSER=&1
define EMAIL=&2
define LASTNAME=&3
define FIRSTNAME=&4

set termout off

column thisuser                  new_value ADDING

select upper(trim('&NEWUSER'))||'_' thisuser from dual;

column timecol                  new_value timestamp
column spool_extension          new_value suffix
SELECT to_char(sysdate,'Mon-dd-yyyy') timecol,'.out' spool_extension FROM sys.dual;

column thisdb                   new_value dbname
SELECT value || '_' thisdb FROM v$parameter WHERE name = 'db_name';

column thishost                 new_value hostname
select replace(host_name,'.aetna.com','') || '_' thishost from v$instance;

--set termout on

set lines 115 pagesize 1000 echo on trim on

prompt

insert into aedba.strong_users values (upper(trim('&NEWUSER')),trim('&EMAIL'),'&LASTNAME','&FIRSTNAME');
commit;

undefine NEWUSER
undefine EMAIL
undefine LASTNAME
undefine FIRSTNAME

exit;

