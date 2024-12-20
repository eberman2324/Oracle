set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select db_unique_name from v$dataguard_config where dest_role='PRIMARY DATABASE';
exit;
