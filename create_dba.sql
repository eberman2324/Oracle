set echo on

spool &&1..DBA

create user &&1 identified by &&1#123;
alter user &&1 temporary tablespace temp;
alter user &&1 default tablespace users;
grant dba to &&1;
alter user &&1 default role dba;
alter user &&1 password expire;

spool off;
exit;

