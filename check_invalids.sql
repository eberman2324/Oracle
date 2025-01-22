
column	Name	format a32
column  owner   format a14
column	type	format a32
column "Last DDL Time"	format a30

-- -------------------------------------------------------------------------------------------------
-- Modified July 27th 2017 (M.Luddy
-- -------------------------------------------------------------------------------------------------

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

spool check_invalids__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

set lines 145
set echo on


select
        owner,
        substr(object_name,1,32) "Name",
        substr(object_type,1,32) "Type" ,
	substr(to_char(last_ddl_time, 'DD-MON-YY HH24:MI:SS'),1,25) "Last DDL Time",
        status
from
        dba_objects
where
        status <> 'VALID'
order by
	4 desc
;
	

spool off;
exit;

