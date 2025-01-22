Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column TODAY NEW_VALUE _DATE
column VERSION NEW_VALUES _VERSION
select to_char(SYSDATE,'fmMonth DD, YYYY') TODAY from DUAL;
select version from v$instance;
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'mm-dd-yyyy__hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on

spool check_log__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

set lines 100

column "L_TS"   format a27

select
        l_id,
--      l_ts,
        substr(to_char(l_ts, 'DD-MON-YY HH24:MI:SS'),1,25) "L_TS",
        l_comment
from
        db_log
order by
        l_id
;

spool off;
exit;
--
