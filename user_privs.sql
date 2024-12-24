set long 1000000

set heading off feedback off verify off line 600 trimspool on term off

column DDL format a999 word_wrap

var v_user clob
var v_sysgrants clob
var v_rolegrants clob
var v_objgrants clob
var v_defroles clob
var v_tsquotas clob

spool &1._user_privs_&2..out APPEND

DECLARE
   noneofthese EXCEPTION;
   PRAGMA EXCEPTION_INIT(noneofthese, -31608);

   l_user varchar2(30) := upper('&3');

begin

   begin

      dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);

      dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'PRETTY',false);

      :v_user := dbms_metadata.get_ddl('USER', l_user);

   exception
      when others then
      begin
         :v_user := '';
         :v_sysgrants := '';
         :v_rolegrants := '';
         :v_objgrants := '';
      end;
   end;

   begin

      :v_sysgrants := dbms_metadata.get_granted_ddl('SYSTEM_GRANT', l_user);

   exception
      when noneofthese
      then
      begin
         :v_sysgrants := '';
         :v_rolegrants := '';
         :v_objgrants := '';
      end;
   end;

   begin

   :v_rolegrants := dbms_metadata.get_granted_ddl('ROLE_GRANT', l_user);

   exception
      when noneofthese
      then
      begin
         :v_rolegrants := '';
         :v_objgrants := '';
      end;
   end;

   begin

   :v_objgrants := dbms_metadata.get_granted_ddl('OBJECT_GRANT', l_user);

   exception
      when noneofthese
      then
      begin
         :v_objgrants := '';
      end;
   end;

   begin

   :v_defroles := dbms_metadata.get_granted_ddl('DEFAULT_ROLE', l_user);

   exception
      when noneofthese
      then
      begin
         :v_defroles := '';
      end;
   end;

   begin

   :v_tsquotas := dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', l_user);

   exception
      when noneofthese
      then
      begin
         :v_tsquotas := '';
      end;
   end;

end;
/

prompt
prompt ---- DDL for User &3 ---;
select :v_user as ddl from dual;

prompt
prompt ---- System Grants for User &3 --;
select :v_sysgrants as ddl from dual;

prompt
prompt ---- Role Grants for User &3--;
select :v_rolegrants as ddl from dual;

prompt
prompt ---- Object Grants for User &3 --;
select :v_objgrants as ddl from dual;

prompt
prompt ---- Default Roles for User &3 --;
select :v_defroles as ddl from dual;

prompt ---- Tablespace Quotas for User &3 --;
select :v_tsquotas as ddl from dual;

prompt ----------------------------------------------------------------------------------;

