select sql_text, EXECUTIONS,CPU_TIME,FETCHES	BUFFER_GETS,DISK_READS, ROWS_PROCESSED from v$sql where module = 'w3wp.exe' and sql_text like '%sp_get_Claim_History_Event%'

select * from v$sqlarea where module = 'w3wp.exe' and sql_text like '%sp_get_Claim_History_Event%'

select * from v$sqlarea where  sql_text like '%stats$sql_summary%'
select * from v$sql where  sql_text like '%stats$sql_summary%'

---Statspack tables

select count(*) from perfstat.stats$sql_summary  where  sql_text  like '%sp_get_Claim_History_Event%'
select count(*) from perfstat.stats$sql_summary  where  text_subset  like '%sp_get_Claim_History_Event%'

select * from perfstat.stats$sql_summary

select * from v$db_object_cache where owner = 'WKAB10' and TYPE = 'PACKAGE'