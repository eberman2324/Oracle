set lin 132
set pagesize 60

COLUMN "Segment"  format a32
column "Type" format a8
column "TS" format a12
column "Owner" format a7
column "Ext" format 999
column "Max E" format 999



break on report;
--compute sum of bytes on report;
compute sum of Megs on report;

spool &&1..seg;

select 
substr(segment_name,1,35) "Segment",
substr(segment_type,1,6) "Type",
substr(tablespace_name,1,12) "TS",
substr(owner,1,7) "Owner",
extents,
-- substr(extents,1,5) "Ext",
max_extents,
--substr(max_extents,1,5) "Max E",
initial_extent "Init",
next_extent "Next",
bytes "Bytes",
bytes/1024/1024 "Megs"
--PCT_INCREASE
--initial_extent/1024/1024 "Init M",
--next_extent/1024/1024 "Next M"
from dba_segments
where tablespace_name = upper('&&1')
--order by segment_name
order by bytes desc, tablespace_name, segment_name
--order by bytes desc, tablespace_name, segment_name
;
spool off;

