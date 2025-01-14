set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_claim_workbasket_stats_&1..out




prompt Script name: gather_claim_workbasket.sql

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on

prompt
prompt Gathering Stats on Table PROD.CODE_ENTRY (Table 1 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CODE_ENTRY', cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.MEMBERSHIP (Table 2 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBERSHIP', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.CLAIM_TOTAL (Table 3 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_TOTAL', degree=>4, cascade=>true, force=>true);
prompt





set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

