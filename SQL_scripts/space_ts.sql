set term off
set heading off

spool tmp7_spool.sql
	select 'spool '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.ts1' 
	from sys.v_$database;
spool off

spool tmp7_vi.sql
	select 'host vi '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.ts1' 
	from sys.v_$database;
spool off


Column 		Tablespace 	format a35
Column 		Size		format a20
Column		USed		format a20
Column		Free		format a20
Column		Total		format a20

Column 		"Tablespace." 		format a35  heading "          "
Column 		"Size."		format a20  heading "     "
Column		"USed."		format a20  heading "     "
Column		"Free."		format a20  heading "     "
Column		"Total."		format a20  heading "      "



@tmp7_spool.sql

set term on
set heading on

set pagesize 40
set lines 130

prompt ====================================================================================================   
prompt .                      TABLESPACE USAGE (DBA_DATA_FILES, DBA_FREE_SPACE)
prompt ====================================================================================================   

select  substr(tablespace_name,1,30)                     		"Tablespace",
        to_char(bytes/1024/1024,'99,999,999,999,999')        		"Size",
       	to_char(nvl(bytes-free,bytes)/1024/1024,'99,999,999,999,999') 	"Used",
       	to_char(nvl(free,0)/1024/1024,'99,999,999,999,999')    		"Free",
       	to_char(nvl(100*(bytes-free)/bytes,100),'999.99')||'%'     	"Used"
from 
	sys.temprpt_status
order 
	by 2 desc;







set feedback off

select rpad('Total',30,'.')                                  "Tablespace.",
       	to_char(sum(bytes),'99,999,999,999,999')                 "Size.",
       	to_char(sum(nvl(bytes-free,bytes)),'99,999,999,999,999') "Used.",
       	to_char(sum(nvl(free,0)),'99,999,999,999,999')           "Free.",
       	to_char((100*(sum(bytes)-sum(free))/sum(bytes)),'999.99')||'%' "Used."
from 
	sys.temprpt_status;

set feedback on





set feedback off

select rpad('Total',30,'.')                                  "Tablespace.",
       	to_char(sum(bytes/1024/1024),'99,999,999,999,999')                 "Size.",
       	to_char(sum(nvl(bytes-free,bytes)/1024/1024),'99,999,999,999,999') "Used.",
       	to_char(sum(nvl(free,0)/1024/1024),'99,999,999,999,999')           "Free.",
       	to_char((100*(sum(bytes)-sum(free))/sum(bytes)),'999.99')||'%' "Used."
from 
	sys.temprpt_status;

set feedback on




set feedback off

select rpad('Total',30,'.')                                  "Tablespace.",
       	to_char(sum(bytes/1024/1024/1024),'99,999,999,999,999')                 "Size.",
       	to_char(sum(nvl(bytes-free,bytes)/1024/1024/1024),'99,999,999,999,999') "Used.",
       	to_char(sum(nvl(free,0)/1024/1024/1024),'99,999,999,999,999')           "Free.",
       	to_char((100*(sum(bytes)-sum(free))/sum(bytes)),'999.99')||'%' "Used."
from 
	sys.temprpt_status;

set feedback on





spool off;

REM  ****************************************
/* run dynamic editor file */
@tmp7_vi.sql

/* Remove temp spool scripts */
host rm tmp7_*.sql
REM  ****************************************
1
