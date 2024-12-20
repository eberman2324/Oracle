set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select distinct blocksize from v$standby_log
exit;
