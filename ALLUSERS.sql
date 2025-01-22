-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.1
-- -------------------------------------------------------------------------------------------------
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
column "username"               format a24
column "STATUS"                 format a22
column "Lock"                   format a20
column "Expire"                 format a20
column "Created"                format a20
column "profile"                format a21
SET LINES 140
SET PAGESIZE 1000

SPOOL /orahome/u01/app/oracle/local/logs/all_users__&&dbname&&hostname&&timestamp&&suffix

select instance from v$thread
;
select profile, count(username) from dba_users group by profile
;

select
        u.username,
        SUBSTR(account_status,1,16) "STATUS",
        TO_CHAR(LOCK_DATE,'MM/DD/YYYY hh:miam') "Lock",
        TO_CHAR(expiry_date,'MM/DD/YYYY hh:miam') "Expire",
        TO_CHAR(CREATED,'MM/DD/YYYY hh:miam') "Created",
        profile
from
        dba_users u
order by
        CREATED,
        username,
        profile
;

exit;

--
-- MCL
--    
