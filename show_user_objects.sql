ttitle off
clear col
clear breaks
clear computes

set pages 1000
SET HEADING ON
SET ECHO OFF
set feedback off

col owner             format a17
col tablespace_name   format a15
col size_MB           format 9999999.99
break on owner skip 1
compute sum of size_MB on owner

accept owner prompt "Enter Owner Name [Enter For All]:"



REM
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column TODAY NEW_VALUE _DATE
column VERSION NEW_VALUES _VERSION
select to_char(SYSDATE,'fmMonth DD, YYYY') TODAY from DUAL;
select version from v$instance;
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.out' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on

spool user_objects__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^




select  owner
,	count(*) count
,       segment_type
,	tablespace_name
,       sum(bytes/1024/1024)   size_MB
from	dba_segments
where	owner = nvl(upper('&owner'),owner)
group by   segment_type
,	   tablespace_name
,          owner
order by owner
,        segment_type
,	 tablespace_name
,        count
,        size_MB
/


spool off;
