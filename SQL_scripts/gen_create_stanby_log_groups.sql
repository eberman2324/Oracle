set head off
set feedback off
spool create_standby_log_groups.out
select 'alter database add standby logfile group 1'||a.group#||' ('''||substr(b.member,1,9)||''') size ' || a.bytes || ';' 
from    v$log a,
        v$logfile b
where
        a.group# = b.group#
/
quit
