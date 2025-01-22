
set pagesize 0
set feed off
column name new_value dbname noprint

select name from v$database;

spool $SQLPATH/set_local_temp_tablespace_&dbname..sql
prompt spool $LOGS/set_local_temp_tablespace_&dbname..out
prompt set echo on
select 'alter user '||username||' LOCAL TEMPORARY TABLESPACE '||TEMPORARY_TABLESPACE||';'
from dba_users
where username not in ('XS$NULL') and local_temp_tablespace='SYSTEM';
prompt spool off
spool off
set feed on
@$SQLPATH/set_local_temp_tablespace_&dbname..sql
