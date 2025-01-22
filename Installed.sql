set pages 999
set lines 150

col c1 		heading 'feature' 		format a65
col c2 		heading 'times|used' 		format 999,999
col c3 		heading 'first|used'
col c4 		heading 'used|now'
col comp_name					format a65

spool Installed__${ORACLE_SID}.out



select
   comp_name,
   version
from
   dba_registry
where
   status = 'VALID';



select
   name c1,
   detected_usages c2,
   first_usage_date c3,
   currently_used c4
from
   dba_feature_usage_statistics
where
   first_usage_date is not null;

 
select
   parameter
from
   v$option
where
   value = 'TRUE'
order by
   parameter;

spool off;
exit;

