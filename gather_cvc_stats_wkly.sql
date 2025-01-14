set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_cvc_stats_&1..out


prompt Script name: gather_cvc_stats_wkly.sql


select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on


prompt
prompt Gathering Stats on Table PROD.CVC_STEP (Table 1 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_STEP', degree=>6, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_INSTANCE_CONTEXT (Table 2 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_INSTANCE_CONTEXT', degree=>6, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_WORK_IN_PROGRESS (Table 2 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_WORK_IN_PROGRESS', degree=>6, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_FAILURE_DETAIL (Table 4 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_FAILURE_DETAIL', degree=>4, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_WORK_VALUE_INSTANCE (Table 5 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_WORK_VALUE_INSTANCE', degree=>4, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_ACQUIRED_MUTEX (Table 6 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_ACQUIRED_MUTEX', degree=>2, cascade=>true,force=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_WAIT_MUTEX (Table 7 of 7);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_WAIT_MUTEX', degree=>4, cascade=>true,force=>true);
prompt


set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

