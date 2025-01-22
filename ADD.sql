-- -------------------------------------------------------------------------------------------------
-- DO NOT CHANGE THIS FILE
-- NEWUSER 3.2
-- Added uppers and trims
-- -------------------------------------------------------------------------------------------------

accept  NEWUSER         char                    PROMPT  "New username  : "
accept  EMAIL           char                    PROMPT  "Email address : "
accept  LASTNAME        char                    PROMPT  "    LAST NAME : "
ACCEPT  FIRSTNAME       char                    PROMPT  "    FIRST NAME: "

set termout off
column thisuser                  new_value ADDING
select upper(trim('&NEWUSER'))||'__' thisuser from dual;
column timecol                  new_value timestamp
column spool_extension          new_value suffix
SELECT to_char(sysdate,'Mon-dd-yyyy') timecol,'.outt' spool_extension FROM sys.dual;
column thisdb                   new_value dbname
SELECT value || '_' thisdb FROM v$parameter WHERE name = 'db_name';
column thishost                 new_value hostname
select replace(host_name,'.aetna.com','') || '_' thishost from v$instance;
set termout on

set lines 115
set pagesize 1000
set echo on

spool /orahome/u01/app/oracle/local/logs/&&ADDING&&dbname&&hostname&&timestamp&&suffix

insert into aedba.strong_users values (upper(trim('&NEWUSER')),trim('&EMAIL'),'&LASTNAME','&FIRSTNAME');

SPOOL off;
exit;
--
-- MCL
-- ---
