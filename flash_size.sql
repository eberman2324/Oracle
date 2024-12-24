set echo on time on 

spool flash_size.out append

SELECT
     SUM(bytes/1024/1024/1024) as "Size(GB)"
FROM
   v$flashback_database_logfile;

spool off;
exit;

