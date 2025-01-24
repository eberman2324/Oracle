set long 2000000000
set heading off
set feedback off
set verify off
set trimspool on
set linesize 1024

select 'drop directory ' || directory_name ||';' as DDL 
  from dba_directories 
order by directory_name
/
