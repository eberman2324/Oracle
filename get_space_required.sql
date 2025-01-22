set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select nvl(round(sum(bytes)/1024/1024,-1),0) from V$datafile where name like '&1%';
exit;
