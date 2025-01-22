set lines 130
prompt
prompt ===========================================
prompt   Standby Redo Log Listing
prompt ===========================================
prompt
column  "Group"         format 999;
column  "Thread"        format 999;
column  "File Location" format A56;
column  "Seq#"          format 999,999;
column  "Grp status"    format a10;
column  "Bytes (K)"     format 9,999,999;
column  "Megs (M)"     format 99,999;

break on "Group" skip 1 nodup;

select
        a.group# "Group",
        a.thread# "Thread",
        b.member "File Location",
        a.SEQUENCE# "Seq#",
        a.archived,
        substr(a.status,1,10) "Grp status",
--        a.bytes/1024 "Bytes (K)",
        a.bytes/1048576 "Megs (M)",
        b.status "MEM status"
from    v$standby_log a,
        v$logfile b
where
        a.group# = b.group#
order by
        1,2,3
;

