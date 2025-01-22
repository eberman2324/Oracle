col "username" for a24

set lines 140 pagesize 1000 trimspool on feed off head off pagesize 999 verify off

spool drop_target_users.sql

prompt
prompt set echo on trimspool on;
prompt

prompt spool drop_target_users.out;

select 'drop user '||username||' cascade;'
from dba_users
where regexp_like (username, '[0123456789]') and (username like 'A______' or username like 'N______') and username NOT IN ('&1')
order by created;

prompt
prompt spool off;
prompt
prompt exit;
prompt

spool off;

