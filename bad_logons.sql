SET LINES 160
SET PAGESIZE 5000
set tab off

column 	os_username	format a24
column 	username	format a18
column 	userhost	format a32
column	TERMINAL	format a32
column 	timestamp	format a32

spool /orahome/u01/app/oracle/local/logs/bad_logons_${ORACLE_SID}.out

select distinct a.os_username, a.username, a.userhost, a.dbid from dba_audit_trail a, v$database d 
where upper(a.os_username) <> a.username
 and (os_username like 'a%' or os_username like 'n%') 
 and a.dbid=d.dbid and username <> 'SC_BASE'
 and os_username <> 'apache'
 and a.returncode = 0 
;

spool off;
exit;

-- 
