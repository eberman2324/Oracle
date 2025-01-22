rem	
rem	Explain plan.
rem

set verify off
set space 1;
set pagesize 100;
set heading on;
set wrap off;
set linesize 150;
set feedback off;

set term off
set heading off

spool tmp7_spool.sql
select 'spool &&1'||'_'||name||'_'||to_char(sysdate,'mondd_hh24miss')||'_'||user||'.exp' from v$database;
spool off

spool tmp7_vi.sql
	select 'host vi &&1'||'_'||name||'_'||to_char(sysdate,'mondd_hh24miss')||'_'||user||'.exp' from v$database;
spool off



set term on
set heading on

rem ****************************************************************

delete from plan_table where statement_id = '&&1';
@tmp7_spool.sql
explain plan set statement_id = '&&1'  for
@&&1..sql
;
set pagesize 100;
set linesize 150;

select cardinality "Rows",
	substr(decode(id,0,'',lpad(' ',2*(level-1))||level||'.'||position)||' '||
       operation||decode(optimizer,NULL,'',decode(id,0,' '||optimizer,'  HINT: '||optimizer))||
       decode(options,NULL,' ',' ('||options||') ')||
       decode(object_name,NULL,' ','of '''||object_name||''''||
              decode(object_type,NULL,'',' ('||object_type||') '))||
       decode(id, 0, decode(position,NULL,'(RULE)','(Cost = '||position||')')
     ),1,150) "Query Plan"
--,cardinality "Rows"
from plan_table
start with id = 0 and statement_id = '&&1'
connect by prior id = parent_id and statement_id = '&&1'
;


--SELECT LPAD(' ',2*(LEVEL-1))||operation||' '||options
--   ||' '||object_name
--   ||' '||DECODE(id, 0, 'Cost = '||position) "Query Plan"
--   FROM plan_table
--   START WITH id = 0 AND statement_id = '&&1'
--   CONNECT BY PRIOR id = parent_id AND statement_id = '&&1'
--;




SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);



set heading off;

select 'Time Stamp:  '||substr(to_char(sysdate,'mm/dd/yy hh24:mi:ss pm'),1,25) "Time Stamp",
       'User:  '||substr(user, 1,10) "User",
       'SID:  '||substr(instance,1,10) "SID"
from v$thread;

set heading on;
set verify on;
spool off;


/* run dynamic editor file */
@tmp7_vi.sql

/* Remove temp spool scripts */
host rm tmp7_*.sql

prompt
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt

