set line 140 trimspool on head on echo off pagesize 999 feed off

col name for a30
col type for a5
col ts for a5

spool run_redef.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on
set echo on timing on head off

DECLARE
   v_table		VARCHAR2(30);
   
   cursor cur_get_tables
   IS
   select table_name  from all_tables where tablespace_name = 'DATA' and owner = 'PROD';
   
BEGIN
   FOR rec_get_tables IN cur_get_tables
   LOOP
      v_table := rec_get_tables.table_name;
    DBMS_REDEFINITION.REDEF_TABLE(uname => 'PROD',tname => v_table,table_part_tablespace => 'PROD_DATA',index_tablespace => 'PROD_INDEX',lob_tablespace => 'PROD_DATA');
   
   END LOOP;
END;
/

set echo off timing off head on feed on
set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off