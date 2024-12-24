col "username" for a24

set lines 140 pagesize 1000 trimspool on feed off head off pagesize 999

spool drop_target_S_ids.sql

prompt
prompt set echo on trimspool on;
prompt

prompt spool drop_target_S_ids.out;

select 'drop user '||username||' cascade ;'
from dba_users
where regexp_like (username, '[0123456789]') and username like 'S______' and username != 'S058102';

prompt
prompt spool off;
prompt
prompt exit;
prompt

spool off;

