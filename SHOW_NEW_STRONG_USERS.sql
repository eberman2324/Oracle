-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.1
-- DO NOT SPOOL OUTPUT
-- -------------------------------------------------------------------------------------------------
-- Modified July 27th for larger FULL name   (M.Luddy)
-- -------------------------------------------------------------------------------------------------
set lines 150
set pagesize 0
set heading off
set feedback 0

column "thishost" format a20
column "instance_name" format a20

column "username" format a10
column "randompass" format a10
column "email_address" format a30
column "fullname" format a50
column "last_name" format a18
column "first_name" format a18

select
        replace(i.host_name,'.aetna.com','') "thishost",
        i.instance_name,
        username,
        randompass,
        email_address,
        first_name||' '||last_name "fullname"
from
        v$instance i,
        aedba.strong_users
where
        username not in (select username from dba_users)
;

exit;
--
-- MCL
-- ---   
