-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.1
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

column "username"               format a22
column "STATUS"                 format a22
column "profile"                format a28
column "email_address"          format a30
column "last_name"              format a14
column "first_name"             format a14
column "Lock"                   format a16
column "Expire"                 format a16
column "Created"                format a16
column "profile"                format a14
SET LINES 142
SET PAGESIZE 1000

SPOOL /orahome/u01/app/oracle/local/logs/who_is_strong__&&dbname&&hostname&&timestamp&&suffix

select username,profile from dba_users where profile not in ('TRUSTED_ID_NO_EXPIRE','STANDARD')
;
select
        u.username,
        s.email_address,
        --s.last_name,
        --s.first_name,
        SUBSTR(account_status,1,16) "STATUS",
        TO_CHAR(lock_date,'MM/DD/YY hh24:mi') "Lock",
        TO_CHAR(expiry_date,'MM/DD/YY hh24:mi') "Expire",
        TO_CHAR(CREATED,'MM/DD/YY hh24:mi') "Created",
        profile
from
        dba_users u,
        AEDBA.strong_users s
where
	PROFILE = 'STANDARD'
	and u.username = s.username (+)
order by
        CREATED,
        username,
        profile
;

prompt
prompt STANDARD Users NOT in strong_users table:
select
        u.username,
        SUBSTR(account_status,1,16) "STATUS",
        TO_CHAR(lock_date,'MM/DD/YY hh24:mi') "Lock",
        TO_CHAR(expiry_date,'MM/DD/YY hh24:mi') "Expire",
        TO_CHAR(CREATED,'MM/DD/YY hh24:mi') "Created",
        profile
from
        dba_users U
where
        PROFILE = 'STANDARD'
	and u.username not in (select username from AEDBA.strong_users)
	and (regexp_like (u.username, '[0123456789]') and (u.username like 'A______' or u.username like 'N______') )
order by
	created,
        username,
        profile
;

spool off;
exit;

rem
-- MCL
-- ---    
