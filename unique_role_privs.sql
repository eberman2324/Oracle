set long 1000000

set heading off feedback off verify off line 600 trimspool on term off

column DDL format a999 word_wrap

var v_role clob
var v_sysgrants clob
var v_objgrants clob
var v_rolegrants clob

spool &1._unique_role_privs_&2..sql APPEND

DECLARE
   noneofthese EXCEPTION;
   PRAGMA EXCEPTION_INIT(noneofthese, -31608);

   l_role varchar2(30) := upper('&&3');
begin

   dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);

   dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'PRETTY',false);   
  
   begin  
      :v_role := dbms_metadata.get_ddl('ROLE', l_role);
   exception
   when others then
      begin
         :v_role := '';
         :v_sysgrants := '';
         :v_objgrants := '';
      end;
   end;

   begin
      :v_sysgrants := dbms_metadata.get_granted_ddl('SYSTEM_GRANT', l_role);
   exception
      when noneofthese
      then 
      begin
            :v_sysgrants := '';
            :v_objgrants := '';
      end;
   end;
   begin
   :v_objgrants := dbms_metadata.get_granted_ddl('OBJECT_GRANT', l_role);
   exception
      when noneofthese
      then
         :v_objgrants := '';
   end;
   begin
   :v_rolegrants := dbms_metadata.get_granted_ddl('ROLE_GRANT', l_role);
   exception
      when noneofthese
      then
         :v_rolegrants := '';
   end;
end;
/

prompt ----------------------------------------------;
prompt;
prompt ---- DDL for Role &&3 ---;
select :v_role as ddl from dual;

prompt;
prompt ---- System Grants for Role &&3 --;
select :v_sysgrants as ddl from dual;

prompt;
prompt ---- Object Grants for Role &&3 --;
select :v_objgrants as ddl from dual;

prompt;
prompt ---- Role Grants for Role &&3 --;
select :v_rolegrants as ddl from dual;

set heading on feedback on

