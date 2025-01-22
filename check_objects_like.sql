set lin 132
set pagesize 60

column bytes	format 999,999,999,999
column Megs	format 999,999


break on report
-- compute sum of bytes on report
compute sum of Megs on report


spool &&1..like

select
substr(segment_name,1,25)	 "Segment",
substr(segment_type,1,4)	 "Type",
substr(tablespace_name,1,12)	 "TS",
--substr(owner,1,7)		 "Owner",
substr(extents,1,5)		 "Ext",
substr(max_extents,1,5)		 "Max E",
initial_extent			 "Init",
next_extent			 "Next",
bytes 				 "Bytes",
bytes/1024/1024			 "Megs",
initial_extent/1024/1024	 "Init M",
next_extent/1024/1024 		 "Next M"
from dba_segments
where segment_name like upper('&&1%')
order by bytes desc
;
