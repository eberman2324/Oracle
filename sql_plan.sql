truncate table plan_table;

set pagesize 500 linesize 200

col operation   format  a50     trunc
col options     format  a25     trunc
col object_name format  a23     trunc
col id          format  9999
col parent_id   format  9999
col position    format  9999
col operations  format  a50

spool explain_plan.out

EXPLAIN PLAN
set statement_id = 'x'
FOR
        SELECT DISTINCT S_REPORT_QUEUE.REPORT_BATCH_ID
		FROM S_REPORT_QUEUE 
		WHERE (S_REPORT_QUEUE.BATCH_DATE >= :B4 
		AND S_REPORT_QUEUE.BATCH_DATE <= :B3 ) 
		AND (( INSTR(:B2, TO_CHAR(COMPANY_ID)) > 0 
		AND :B1 = 'F') 
		OR (INSTR(:B2, TO_CHAR(COMPANY_ID)) = 0 
		AND :B1 = 'N') 
		OR :B1 = 'A')
		/

select lpad(' ',2*level) || operation operations,options,object_name,cost,cardinality,bytes
from plan_table
where statement_id = 'x'
connect by prior id = parent_id and statement_id = 'x'
start with id = 1 and statement_id = 'x'
order by id;

spool off