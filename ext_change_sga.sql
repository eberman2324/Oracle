set trimspool on feed off echo off head off line 100 term off verify off

spool &1._change_sga_&2..sql

select 'spool &1._change_sga_&2..out' from dual;

prompt
prompt set echo on term on line 100;

select 'alter system set sga_target='||value||' scope=spfile;' from v$parameter where name = 'sga_target';
select 'alter system set sga_max_size='||value||' scope=spfile;' from v$parameter where name = 'sga_max_size';
--prompt alter system reset pga_aggregate_limit;;
select 'alter system set pga_aggregate_target='||value||' scope=spfile;' from v$parameter where name = 'pga_aggregate_target';
--select 'alter system set pga_aggregate_limit='||value||' scope=spfile;' from v$parameter where name = 'pga_aggregate_limit';
select 'alter system set db_recovery_file_dest_size='||value||' scope=spfile;' from v$parameter where name = 'db_recovery_file_dest_size';

prompt
prompt spool off ;
prompt

spool off;

exit;

