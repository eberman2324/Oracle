set lines 230
set pagesize 30
set echo on

set termout off
column timecol                  new_value timestamp
column spool_extension          new_value suffix
SELECT to_char(sysdate,'Mon-dd-yyyy') timecol,'.outt' spool_extension FROM sys.dual;
column thishost                 new_value hostname
select replace(host_name,'.aetna.com','') || '_' thishost from v$instance;
set termout on

column HEADER_STATUS 	format a14
column MOUNT_STATUS 	format a12
column NAME		format a18
column LABEL		format a12
column PATH		format a30

spool /orahome/u01/app/oracle/local/logs/showasm__&&hostname&&timestamp&&suffix

select
  MOUNT_STATUS  ,
  HEADER_STATUS ,
  OS_MB,
  TOTAL_MB ,
  FREE_MB  ,
  SECTOR_SIZE,
  LOGICAL_SECTOR_SIZE,
  substr(NAME,1,20) "Name",
  substr(LABEL,1,10) "Label",
  substr(PATH,1,50) "Path"
from
        v$asm_disk
order by
        path,
        name
;
spool off;
-- MCL
