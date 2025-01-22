-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.2
-- changed STRONG profile to STANDARD profile
-- DO NOT SPOOL OUTPUT 
-- -------------------------------------------------------------------------------------------------
-- 
set echo on ;

create user &1 
identified by "&2" 
default tablespace USERS 
quota unlimited on USERS
temporary tablespace temp
profile STANDARD;
--
grant APP_USER_ROLE to &1;
--
alter user &1 default role APP_USER_ROLE;
--
exit;
--
-- MCL 
-- ---    
