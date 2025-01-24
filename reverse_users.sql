set long 2000000000
set heading off
set feedback off
set verify off
set trimspool on
set pagesize 0
undefine what_role
set linesize 1024
column DDL format a999 word_wrap

DECLARE
   noneofthese EXCEPTION;
   PRAGMA EXCEPTION_INIT(noneofthese, -31608);
begin
   dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
end;
/

select dbms_metadata.get_ddl('USER', username) as DDL 
  from dba_users 
 where username not in (select user_name from SYS.default_pwd$)
   and username not in ('MYPIHMS')
order by username
/

select 'GRANT ' || granted_role || ' to ' || grantee || decode(admin_option, 'YES', ' WITH ADMIN OPTION;', 'NO', ';')
  from dba_role_privs 
 where grantee not in (select user_name from SYS.default_pwd$)
   and grantee not in ('MYPIHMS')
order by grantee
/

select 'GRANT ' || privilege || ' to ' || grantee || decode(admin_option, 'YES', ' WITH ADMIN OPTION;', 'NO', ';')
  from dba_sys_privs 
 where grantee not in (select user_name from SYS.default_pwd$)
   and grantee not in ('MYPIHMS')
order by grantee
/

-- Get system level object grants
select 'GRANT ' || tp.privilege || ' on ' || table_name || ' to ' 
       || tp.grantee || decode(tp.grantable, 'YES', ' WITH GRANT;', 'NO', ';')
  from dba_tab_privs tp,
       dba_objects o
 where tp.grantee not in (select user_name from SYS.default_pwd$)
   and tp.owner = o.owner
   and tp.table_name = o.object_name
   and o.object_type in ('DIRECTORY')
   and tp.grantee not in ('MYPIHMS')
order by tp.grantee
/

