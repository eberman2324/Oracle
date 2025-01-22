SET LINES 160
SET PAGESIZE 5000
set tab off

column 	os_username	format a24
column 	username	format a18
column 	userhost	format a32
column	TERMINAL	format a32
column 	timestamp	format a32

--spool /orahome/u01/app/oracle/local/logs/failed_logons_${ORACLE_SID}.out

spool failed.out

select 
    OS_USERNAME,
    USERNAME,
    USERHOST,
    TERMINAL,
    substr(to_char(timestamp, 'MM/DD/YYYY  hh:mi:ss am'),1,30)	TS,
    RETURNCODE
from 
    dba_audit_trail 
where 
    TIMESTAMP > sysdate - 3
    AND RETURNCODE = 1017
 ORDER BY
    timestamp
;

spool off;
exit;

-- 
