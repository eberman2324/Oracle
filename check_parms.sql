column  Name    format a30
set lines 140

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

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^
spool check_parms__&&dbname&&timestamp&&suffix


show parameter open_cursors
show parameter _optimizer_cost_based_transformation
show parameter compatible
show parameter cursor_sharing
show parameter db_cache_advice
show parameter db_file_multiblock_read_count
show parameter processes
show parameter query_rewrite

spool off;
exit;
