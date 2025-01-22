-- connect apps/Rdy2Rock
connect apps/Ke88l3


Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.out' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool check_fnd__&&dbname&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

set echo on 

select node_name, node_mode, support_cp,support_web, support_admin, support_forms from applsys.FND_NODES;

spool off;
exit;

