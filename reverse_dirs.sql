set long 2000000000
set heading off
set feedback off
set verify off
set trimspool on
undefine what_role
column DDL format a999 word_wrap
set linesize 1024

DECLARE
   noneofthese EXCEPTION;
   PRAGMA EXCEPTION_INIT(noneofthese, -31608);
begin
   dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
end;
/

select dbms_metadata.get_ddl('DIRECTORY', directory_name) as DDL 
  from dba_directories 
order by directory_name
/
