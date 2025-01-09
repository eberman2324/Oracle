select sql_id, child_number, name, position, cast(value_string as varchar2(20)) as value_string, cast(value_anydata as varchar2(20)) as value_anydata
from v$sql_bind_capture
where sql_id='&what_sql_id'
order by 1,2,4
/

-- Historic + latest
   select 
sn.END_INTERVAL_TIME,
sb.NAME,
sb.VALUE_STRING 
from 
DBA_HIST_SQLBIND sb,
DBA_HIST_SNAPSHOT sn
where 
sb.sql_id='a7fgy9kkxntq5' and
sb.WAS_CAPTURED='YES' and
sn.snap_id=sb.snap_id
order by 
sb.snap_id,
sb.NAME;