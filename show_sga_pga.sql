set echo off linesize 120 trimspool on

spool &1._show_sga_pga_&2..out

show parameter sga_target
prompt
show parameter sga_max_size
prompt
show parameter pga_aggregate_target
prompt
show parameter pga_aggregate_limit
prompt

spool off;

exit;

