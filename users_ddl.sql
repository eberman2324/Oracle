SET ECHO off 
REM NAME: TFSCRUSR 
REM USAGE:"@path/tfscrusr" 
REM -------------------------------------------------------------------------- 
REM REQUIREMENTS: 
REM DBA role 
REM ------------------------------------------------------------------------- 
REM PURPOSE: 
REM This script will in turn create a script to build all the 
REM users in the database. This created script, create_users.sql, 
REM can be run with the DBA role or 'CREATE USER' system privilege. 
REM ------------------------------------------------------------------------- 
REM EXAMPLE: 
REM CREATE USER scott 
REM IDENTIFIED BY VALUES 'F894844C34402B67' 
REM DEFAULT TABLESPACE TOOLS 
REM TEMPORARY TABLESPACE TEMP 
REM QUOTA -1 ON TOOLS 
REM QUOTA -1 ON USERS 
REM PROFILE DEFAULT; 
REM 
REM CREATE USER shaq 
REM IDENTIFIED BY VALUES '3835037579B13ACA' 
REM DEFAULT TABLESPACE USERS 
REM TEMPORARY TABLESPACE TEMP 
REM QUOTA -1 ON USERS 
REM PROFILE DEFAULT; 
REM 
REM ------------------------------------------------------------------------- 
REM DISCLAIMER: 
REM This script is provided for educational purposes only. It is NOT 
REM supported by Oracle Support Services. 
REM The script has been tested and appears to work as intended. 
REM You should always run new scripts on a test instance initially. 
REM -------------------------------------------------------------------------- 
REM Main text of script follows: 


set verify off; 
set termout off; 
set feedback off; 
set echo off; 
set pagesize 0; 

set termout on 
select 'Creating user build script...' from dual; 
set termout off; 

create table usr_temp( lineno number, 
usr_name varchar2(30),text varchar2(80)) 
/ 

DECLARE 
CURSOR usr_cursor IS select username, 
password, 
default_tablespace, 
temporary_tablespace, 
profile 
from sys.dba_users 
where username != 'SYS' AND username != 'SYSTEM' 
order by username; 

CURSOR qta_cursor(c_usr VARCHAR2) IS select tablespace_name, 
max_bytes 
from sys.dba_ts_quotas 
where username = c_usr; 

lv_username sys.dba_users.username%TYPE; 
lv_password sys.dba_users.password%TYPE; 
lv_default_tablespace sys.dba_users.default_tablespace%TYPE; 
lv_temporary_tablespace sys.dba_users.default_tablespace%TYPE; 
lv_profile sys.dba_users.profile%TYPE; 
lv_tablespace_name sys.dba_ts_quotas.tablespace_name%TYPE; 
lv_max_bytes sys.dba_ts_quotas.max_bytes%TYPE; 
lv_string VARCHAR2(80); 
lv_lineno number:=0; 

procedure write_out(p_line INTEGER, p_name VARCHAR2, 
p_string VARCHAR2) is 
begin 
insert into usr_temp(lineno,usr_name,text) values 
(p_line,p_name,p_string); 
end; 


BEGIN 
OPEN usr_cursor; 
LOOP 
FETCH usr_cursor INTO lv_username, 
lv_password, 
lv_default_tablespace, 
lv_temporary_tablespace, 
lv_profile; 
EXIT WHEN usr_cursor%NOTFOUND; 

lv_lineno:=1; 
lv_string:=('CREATE USER '||lower(lv_username)); 
write_out(lv_lineno,lv_username,lv_string); 
lv_lineno:=lv_lineno+1; 
if lv_password IS NULL then 
lv_string:='IDENTIFIED EXTERNALLY'; 
else 
lv_string:=('IDENTIFIED BY VALUES '''||lv_password||''''); 
end if; 
write_out(lv_lineno,lv_username,lv_string); 
lv_lineno:=lv_lineno+1; 
lv_string:='DEFAULT TABLESPACE '||lv_default_tablespace; 
write_out(lv_lineno,lv_username,lv_string); 
lv_lineno:=lv_lineno+1; 
lv_string:='TEMPORARY TABLESPACE '||lv_temporary_tablespace; 
write_out(lv_lineno,lv_username,lv_string); 
lv_lineno:=lv_lineno+1; 

OPEN qta_cursor(lv_username); 
LOOP 
FETCH qta_cursor INTO lv_tablespace_name, 
lv_max_bytes; 
EXIT WHEN qta_cursor%NOTFOUND; 
lv_lineno:=lv_lineno+1; 
if lv_max_bytes IS NULL then 
lv_string:='QUOTA UNLIMITED ON '||lv_tablespace_name; 
else 
lv_string:='QUOTA '||lv_max_bytes||' ON '||lv_tablespace_name; 
end if; 
write_out(lv_lineno,lv_username,lv_string); 
END LOOP; 
CLOSE qta_cursor; 
lv_string:=('PROFILE '||lv_profile||';'); 
write_out(lv_lineno,lv_username,lv_string); 
lv_lineno:=lv_lineno+1; 
lv_string:=' '; 
write_out(lv_lineno,lv_username,lv_string); 
END LOOP; 
CLOSE usr_cursor; 

END; 
/ 

spool create_users.sql 
set heading off 
set recsep off 
col test format a80 word_wrap 


select text 
from usr_temp 
order by usr_name, lineno; 

spool off; 

drop table usr_temp; 

exit 
 
   
