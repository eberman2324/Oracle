column "username"               format a24
column "STATUS"                 format a22
column "Lock"                   format a20
column "Expire"                 format a20
column "Created"                format a20
column "profile"                format a21

SET LINES 140
SET PAGESIZE 1000
SET TERM OFF
SET FEED OFF

spool current_s_ids.out

select instance from v$thread ;
select profile, count(username) from dba_users group by profile ;
select
        u.username,
        SUBSTR(account_status,1,16) "STATUS",
        TO_CHAR(LOCK_DATE,'MM/DD/YYYY hh:miam') "Lock",
        TO_CHAR(expiry_date,'MM/DD/YYYY hh:miam') "Expire",
        TO_CHAR(CREATED,'MM/DD/YYYY hh:miam') "Created",
        profile
from
        dba_users u
where
        regexp_like (username, '[0123456789]') and username like 'S______' and username != 'S058102'
order by
        CREATED,
        username,
        profile ;

spool off;

set pagesize 0
set lines 50
set heading off
set feedback off

spool export_S.par

select username||','
from dba_users
where regexp_like (username, '[0123456789]') and username like 'S______' and username != 'S058102'
order by created;

spool off;

spool DROP_S_ids.sql

select '-- Drop user '||username||';'
from dba_users
where regexp_like (username, '[0123456789]') and username like 'S______' and username != 'S058102'
order by created;

spool off;

