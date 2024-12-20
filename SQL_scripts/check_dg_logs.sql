set lines 110
set echo on

column  "First Time"    format a25
column  "Next Time"     format a25

spool check_dg_logs.outt


SELECT GROUP#,THREAD#,SEQUENCE#,ARCHIVED,STATUS FROM V$STANDBY_LOG;

SELECT
        DEST_ID,
        SEQUENCE#,
        FIRST_TIME,
        NEXT_TIME,
        substr(to_char(first_time, 'mm-dd-yyyy__hh24:mi:ss'),1,25) "First Time",
        substr(to_char(next_time, 'mm-dd-yyyy__hh24:mi:ss'),1,25) "Next Time"
FROM
        V$ARCHIVED_LOG
WHERE
	--FIRST_TIME > SYSDATE - 1
	FIRST_TIME > SYSDATE - 4/24
	and DEST_ID = 2
ORDER BY
        SEQUENCE#;


archive log list;

--      on standby              SELECT SEQUENCE#,APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;



spool off;
exit;


-- 240 / 1440  is minutes  for 4 hours ago
-- 4/24 is for hours  for 4 hours ago
-- 6/24 is for 6 hours ago......
