set long 1000000 trimspool on linesize 300 pagesize 0 verify off feed off echo off
column DDL format A999 word_wrap

var v_dir clob

spool replace_directory.sql

prompt
prompt set echo on trimspool on sqlblanklines on; 
prompt
prompt spool replace_directory.out
prompt

declare
 no_dir exception;
 pragma exception_init( no_dir, -31603 );

 no_exist exception;
 pragma exception_init( no_exist, -31608 );

begin

begin

dbms_metadata.set_transform_param(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', TRUE);

dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'PRETTY',FALSE);

:v_dir := dbms_metadata.get_ddl('DIRECTORY','DATA_PUMP_DIR');

exception
 when no_dir then
 begin 
  :v_dir := '';
 end;

end;

end;
/

select :v_dir as DDL from dual;

prompt

prompt
prompt spool off
prompt
spool off

spool grant_directory.sql

prompt
prompt set echo on trimspool on sqlblanklines on; 
prompt
prompt spool grant_directory.out
prompt

select distinct 'GRANT '||privilege||' ON '||
decode(privilege, 'READ', 'DIRECTORY ', 'WRITE', 'DIRECTORY ', owner || '.') || table_name || ' to '||
grantee|| decode(grantable, 'YES', ' with grant option', NULL)||
decode(hierarchy, 'YES', ' with hierarchy option', NULL) || ';'
from dba_tab_privs
where PRIVILEGE in ('READ','WRITE','EXECUTE')
and table_name in (select directory_name from dba_directories where directory_name = 'DATA_PUMP_DIR');

prompt
prompt spool off
prompt
spool off

exit

