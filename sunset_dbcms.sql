Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/sunset_dbcms_user__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

GRANT SELECT ON SYS.USER$ TO S058102;
GRANT SELECT ON SYS.V_$DATABASE TO S058102;
GRANT SELECT ON SYS.V_$INSTANCE TO S058102;
GRANT SELECT ON SYS.V_$NLS_PARAMETERS TO S058102;
GRANT SELECT ON SYS.V_$SESSION TO S058102;
GRANT SELECT ON SYS.V_$DATABASE TO S058102;
GRANT SELECT ON SYS.V_$INSTANCE TO S058102;
GRANT SELECT ON SYS.V_$NLS_PARAMETERS TO S058102;
GRANT SELECT ON SYS.V_$SESSION TO S058102;
grant select on sys.user$ to s058102;
grant select on sys.registry$sqlpatch to S058102;

drop user dbcms cascade;

spool off

