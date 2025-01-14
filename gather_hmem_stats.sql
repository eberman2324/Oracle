set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_hmem_stats_&1..out


prompt Script name: gather_hmem_stats.sql

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on




prompt
prompt Gathering Stats on Table PROD.FLUX_ACTION (Table 1 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_ACTION', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_ACTION_RUN (Table 2 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_ACTION_RUN', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_CLUSTER (Table 3 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_CLUSTER', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_FLOW (Table 4 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_FLOW', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_FLOW_CHART (Table 5 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_FLOW_CHART', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_FLOW_CONTEXT (Table 6 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_FLOW_CONTEXT', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_PK (Table 7 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_PK', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_READY (Table 8 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_READY', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_TIMER_TRIGGER (Table 9 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_TIMER_TRIGGER', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.FLUX_VARIABLE (Table 10 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FLUX_VARIABLE', cascade=>true, force=>true);
prompt


prompt
prompt Gathering Stats on Table PROD.MEMBER_SELECTIONS (Table 11 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_SELECTIONS', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.BENEFIT_DEFINITION (Table 12 of 12);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BENEFIT_DEFINITION', cascade=>true, force=>true);
prompt


set head on timing off


select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

