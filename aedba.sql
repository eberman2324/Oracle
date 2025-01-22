set echo on

spool aedba__${ORACLE_SID}.out

grant dba to aedba;
alter user aedba default role dba;
grant create any directory to AEDBA;

spool off;
exit;

