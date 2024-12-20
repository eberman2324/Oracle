set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select dbid from v$database;
exit;
