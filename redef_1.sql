set line 140 trimspool on head on echo off pagesize 999 feed off

col name for a30
col type for a5
col ts for a5

spool redef_1.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on
set echo on timing on head off

EXEC DBMS_REDEFINITION.REDEF_TABLE(uname => 'PROD',tname => 'CVC_STEP',table_part_tablespace => 'PROD_DATA',index_tablespace => 'PROD_INDEX',lob_tablespace => 'PROD_DATA');

                                   
set echo off timing off head on feed on
set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

