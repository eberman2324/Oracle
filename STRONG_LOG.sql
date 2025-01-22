-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.2
-- -------------------------------------------------------------------------------------------------
Rem
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
Rem
SET TERMOUT OFF
column timecol                  new_value timestamp
column spool_extension          new_value suffix
SELECT to_char(sysdate,'Mon-dd-yyyy') timecol,'.output' spool_extension FROM sys.dual;
column thisdb                   new_value dbname
SELECT value || '_' thisdb FROM v$parameter WHERE name = 'db_name';
column thishost                 new_value hostname
select replace(host_name,'.aetna.com','') || '_' thishost from v$instance;
set termout on
Rem
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^
Rem

SET LINES 142
SET PAGESIZE 1000

SPOOL /orahome/u01/app/oracle/local/logs/strong_log__&&dbname&&hostname&&timestamp&&suffix

set lines 120
column username format a18
column value    format a80

select * from AEdba.strong_log order by 1;

spool off;
exit;  
--
