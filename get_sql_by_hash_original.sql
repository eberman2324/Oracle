REM **
REM ** Script: get_sql_by_address.sql
REM ** Descr: Shows the SQL for a given sql_address
REM **        
REM **
set pagesize 1000
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
clear breaks
clear columns
set recsep wrapped