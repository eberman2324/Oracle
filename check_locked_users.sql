
column username  format a22
column account_status format a18

COLUMN "Locked Date" FORMAT A25 
COLUMN "Expired Data" FORMAT A25

column  Name    format a30

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

spool check_locked_users__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

set lines 130
set echo on


select 
	username,
	account_status,
	substr(to_char(LOCK_DATE, 'DD-MON-YY HH24:MI:SS'),1,25) "Locked Date", 
	substr(to_char(EXPIRY_DATE, 'DD-MON-YY HH24:MI:SS'),1,25) "Expired Data" ,
	profile
from
	dba_users
order by
	expiry_date;


select 
	username,
	account_status,
	substr(to_char(LOCK_DATE, 'DD-MON-YY HH24:MI:SS'),1,25) "Locked Date", 
	substr(to_char(EXPIRY_DATE, 'DD-MON-YY HH24:MI:SS'),1,25) "Expired Data" ,
	profile
from
	dba_users
where
	account_status <> 'OPEN'
order by
	expiry_date;



spool off;


exit;
