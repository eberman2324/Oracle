Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/move_ojvmsys__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


drop user OJVMSYS cascade; 
 drop synonym ojds$node_number$; 
 drop synonym ojds$bindings$; 
 drop synonym ojds$inode$; 
 drop synonym ojds$attributes$; 
 drop synonym ojds$refaddr$; 
 drop synonym ojds$permissions$; 
 drop synonym ojds$shared$obj$seq$; 
 drop synonym ojds$shared$obj$; 
 drop public synonym ojds_namespace; 
 drop package ojds_namespace; 
 drop trigger OJDS$ROLE_TRIGGER$; 
 delete from duc$ where OWNER = 'SYS' and PACK = 'OJDS_CONTEXT' and PROC = 'USER_DROPPED'; 
 drop package ojds_context; 
 commit; 
 grant resource, unlimited tablespace to OJVMSYS identified by "!Temppass1"; 
 alter user OJVMSYS account lock password expire default tablespace SYSTEM; 
 @?/javavm/install/jvm_ojds.sql 
 call dbms_java.grant_permission('PUBLIC', 'SYS:java.io.FilePermission', 'dummy', ''); 
 call dbms_java.grant_permission('PUBLIC', 'SYS:java.io.FilePermission', 'dummy', ''); 
 commit; 

declare
l_username varchar2(30) := 'OJVMSYS';
l_pwd_piece1 varchar2(20) := lower(substr(dbms_random.string('a',9),1,9));
l_pwd_piece2 varchar2(20) := to_char(trunc(dbms_random.value(10,99)));
l_pwd_piece3 varchar2(5) := upper(dbms_random.string('A',4));
l_pwd_piece4 varchar2(2) := '#*';
l_pwd varchar2(20);
l_sql varchar2(200);

begin
DBMS_OUTPUT.PUT_LINE (l_username);
  l_pwd := trim(l_pwd_piece1) || trim(l_pwd_piece2) || trim(l_pwd_piece3) || trim(l_pwd_piece4);
  execute immediate 'alter user ' || l_username || ' identified by "'||l_pwd||'"

account lock';
end;
/
