
column	GRANTEE		format a32
column 	OWNER		format a12
column	GRANTOR		format a12
column	PRIVILEGE	format a16
column  last_name	format a14
column	first_name	format a21

set lines 135
set pagesize 20




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

spool check_HE___&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^



select * from dba_role_privs where granted_role in ('HE_OLTP_ROLE','READ_ONLY') ORDER BY 2,1;
SELECT instance_name from v$instance;
spool off;
exit;
