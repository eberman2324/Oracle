set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_supplier_stats_&1..out


prompt Script name: gather_supplier_stats.sql

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on

prompt
prompt Gathering Stats on Table PROD.SUPPLIER_LOCATION (Table 1 of 3);
--exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_LOCATION', degree=>6, cascade=>true, force=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_LOCATION', no_invalidate=>true, degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.SUPPLIER (Table 2 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.SUPPLIER_NETWORK (Table 3 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_NETWORK', degree=>6, cascade=>true, force=>true);
prompt

set head on timing off


select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

