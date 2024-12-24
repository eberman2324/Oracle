set lines 140 pagesize 1000 trimspool on feed off head off pagesize 999 verify off

spool &1._unlock_user_accounts_&2..sql

prompt
prompt set echo on trimspool on;
prompt

prompt spool &1._unlock_user_accounts_&2..out;

--Below list commented due to source db being TC which is masked
--select 'alter user '||username||' account unlock;'
--from dba_users
--where regexp_like (username, '[0123456789]') 
--and (username like 'A______' 
-- or   username like 'N______')
--and oracle_maintained = 'N'
--and username not in
--(
--'A123456'
--)
--order by username
--/

prompt
prompt spool off;
prompt

spool off

