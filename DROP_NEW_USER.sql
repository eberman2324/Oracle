-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.1
-- DO NOT SPOOL OUTPUT
-- -------------------------------------------------------------------------------------------------
set echo on ;

drop user &&1 cascade;
delete from aedba.strong_users where username=upper('&&1');

exit;
--
-- MCL
-- ---   
