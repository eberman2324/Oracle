set lines 1024 pagesize 0 trimspool on feed off head off verify off

spool &1._preserve_&3._pswd_&2..sql

prompt
prompt set echo on trimspool on lines 1024
prompt

prompt spool &1._preserve_&3._pswd_&2..out
prompt
prompt ALTER PROFILE "TRUSTED_ID_NO_EXPIRE" LIMIT PASSWORD_REUSE_MAX UNLIMITED PASSWORD_REUSE_TIME UNLIMITED;;
prompt

SELECT 'ALTER USER '||name||' IDENTIFIED BY VALUES '||chr(39)||spare4||';'||password||chr(39)||';'
FROM user$
WHERE name='&3';

prompt;
prompt ALTER PROFILE "TRUSTED_ID_NO_EXPIRE" LIMIT PASSWORD_REUSE_MAX 6 PASSWORD_REUSE_TIME 365;;
prompt
prompt spool off;
prompt
prompt exit;
prompt

spool off;

exit

