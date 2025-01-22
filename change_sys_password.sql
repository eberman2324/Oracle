set echo off linesize 120 trimspool on

spool &1._change_sys_password_&2..out

alter user sys identified by "Locked#99999";

spool off;

exit;

