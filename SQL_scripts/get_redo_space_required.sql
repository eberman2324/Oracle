set feedback off
set head off
set verify off
set pagesize 0
set echo off
whenever sqlerror exit 1
select nvl(round(sum(bytes)/1024/1024,-1),0) from V$logfile f, v$log l where  member like '&1%' and f.group#=l.group#;
exit;
