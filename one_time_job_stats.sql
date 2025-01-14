set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool one_time_job_stats_&1..out

prompt Script name: one_time_job_stats.sql


select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on


prompt
prompt Gathering Stats on Table PROD.BLOB_ACCOUNT(Table 1 of 1);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BLOB_ACCOUNT', degree=>6, cascade=>true, force=>true);
prompt








set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

