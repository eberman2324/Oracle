REM **
REM ** Script: get_sql_by_address.sql
REM ** Descr: Shows the SQL for a given sql_address
REM **        
REM **
spool H:\Data\sqlbyHash.out
REM set pagesize 1000
REM set linesize 5024 
set verify off
set recsep off

undefine what_hash
break on which_sql noduplicates
column piece noprint
column ACCESS_PREDICATES format a80 wrap
column FILTER_PREDICATES format a80 wrap

select st.piece, sql_text
from v$sqltext_with_newlines st
where st.hash_value = '&&what_hash'
order by 1
/

select sa.hash_value, sa.module, sa.action,  sa.optimizer_mode, sa.buffer_gets, sa.executions, sa.disk_reads
from v$sqlarea sa
where sa.hash_value = '&&what_hash'
order by 1
/

select id, parent_id, cast( substr(lpad(' ', 2*depth) 
       || operation || ' ' || options 
       || decode(object_name, null, '', ' (' || object_owner || '.' ||object_name || ') ') 
       || decode(optimizer, null, '', ' MODE=' || optimizer), 1, 115) as VARCHAR2(200)) as plan,
       cost
  from v$sql_plan 
 where hash_value='&&what_hash' 
order by id, 
         parent_id, 
         position
/
prompt Access Predicates
select id, access_predicates
  from v$sql_plan 
 where hash_value='&&what_hash' 
   and access_predicates is not null
order by id
/
Prompt Filter Predicates
select id, filter_predicates
  from v$sql_plan 
 where hash_value='&&what_hash' 
   and filter_predicates is not null
order by id
/


select hash_value, child_number, name, position, cast(value_string as varchar2(20)) as value_string, cast(value_anydata as varchar2(20)) as value_anydata
from v$sql_bind_capture
where hash_value='&&what_hash'
order by 1,2,4
/

select PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID, OBJECT_NAME, OBJECT_TYPE
from v$session, dba_objects where SID = '&&what_SID'
and PLSQL_ENTRY_OBJECT_ID = object_id
and owner = '&&what_OWNER'
/

clear breaks
clear columns
set recsep wrapped
spool off