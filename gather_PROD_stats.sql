col type for a5
col ts for a5

spool gather_PROD_stats.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on

set echo on timing on head off

execute dbms_stats.gather_schema_stats('PROD',degree=>24); 

set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off