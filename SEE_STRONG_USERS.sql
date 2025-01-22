-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.1
-- -------------------------------------------------------------------------------------------------
set lines 140
--set pagesize 0
--set heading off
--set feedback 0

column "thishost" 		format a10
column "instance_name" 		format a10
column "username" 		format a10
column "randompass" 		format a10
column "email_address" 		format a50
column "fullname" 		format a30
column "last_name" 		format a32
column "first_name" 		format a32

/*
SQL> desc strong_users
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 USERNAME                                           VARCHAR2(10)
 EMAIL_ADDRESS                                      VARCHAR2(50)
 LAST_NAME                                          VARCHAR2(50)
 FIRST_NAME                                         VARCHAR2(50)
*/

spool /orahome/u01/app/oracle/local/logs/see_strong_users.out

prompt
prompt Currently in strong_users table:
prompt
select
        username,
        email_address,
        last_name,
        first_name
from
        aedba.strong_users
order by
	username
;

prompt
prompt New Strong not yet created:
prompt

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
order by
	username
;

exit;
--
-- MCL 
-- ---    
