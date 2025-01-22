set lines 140 pagesize 1000 trimspool on feed off head off pagesize 999 verify off

spool &1._lock_user_accounts.sql

prompt
prompt set echo on trimspool on;
prompt

prompt spool lock_user_accounts.out;


select 'alter user '||username||' account lock;'
from dba_users
where regexp_like (username, '[0123456789]')
and (username like 'A______'
 or   username like 'N______')
and oracle_maintained = 'N'
and username not in
(
'A236120',
'A738300',
'A729219'
)
order by username
/
prompt
prompt spool off;
prompt
prompt exit;
prompt

spool off;

exit

