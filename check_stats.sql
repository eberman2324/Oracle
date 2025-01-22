
column		owner		format a18
column		table_name	format a32

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

spool check_STATS__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

set lines 115
set echo on


select owner, table_name, num_rows from dba_tables where owner = '&1' order by num_rows, table_name;

spool off;
exit;
