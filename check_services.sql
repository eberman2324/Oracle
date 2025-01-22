set echo on

spool check_names.out


column name             format a20
column network_name     format a25

select name, network_name from dba_services;


spool off;
exit;
