set term off
set heading off

spool tmp7_spool.sql
	select 'spool '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.ts' 
	from sys.v_$database;
spool off

spool tmp7_vi.sql
	select 'host vi '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.ts' 
	from sys.v_$database;
spool off

@tmp7_spool.sql

set term on
set heading on

set pagesize 40
-- set lines 150
SET LINES 140

prompt ==============================================================================================================   
prompt .                      TABLESPACE USAGE (DBA_DATA_FILES, DBA_FREE_SPACE)
prompt ==============================================================================================================   

select  
	substr(tablespace_name,1,16)                      					"Tablespace",
        to_char(bytes/1024/1024,'99,999,999,999')         					"Allocated (M)",
       	to_char(nvl(bytes-free,bytes)/1024/1024,'99,999,999,999')   				"Used (M)",
       	to_char(nvl(free/1024/1024,0),'99,999,999,999')             				"Free (M)",
       	to_char(nvl(100*(bytes-free)/bytes,100),'999.99')||'%'     				"% Used",
--       	to_char((nvl(bytes-free,bytes)/1024/1024)/.8,'99,999,999,999')   			"80% Full" ,
--       	to_char((nvl(bytes-free,bytes)/1024/1024)/.82,'99,999,999,999')   			"82% Full" ,
--       	to_char((nvl(bytes-free,bytes)/1024/1024)/.85,'99,999,999,999')   			"85% Full" ,
       	to_char(((nvl(bytes-free,bytes)/1024/1024)/.8) - bytes/1024/1024,'99,999,999,999')   	"80% By Adding",
       	to_char(((nvl(bytes-free,bytes)/1024/1024)/.82) - bytes/1024/1024,'99,999,999,999')   	"82% By Adding",
       	to_char(((nvl(bytes-free,bytes)/1024/1024)/.85) - bytes/1024/1024,'99,999,999,999')   	"85% By Adding"
from 	
	sys.temprpt_status
where 
	nvl(100*(bytes-free)/bytes,100) >= 80
order by 
	5 desc;
--order by 1;


spool off;

REM  ****************************************
/* run dynamic editor file */
@tmp7_vi.sql

/* Remove temp spool scripts */
host rm tmp7_*.sql
REM  ****************************************

