set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select 1, round(free_mb,-1) from V$ASM_DISKGROUP where name=&1;
exit;
