set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on


spool gather_weekly_stats_&1..out


prompt Script name: gather_weekly_stats.sql


select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on


prompt
prompt Gathering Stats on Table PROD.TRANSFORMED_DELIVERED_SERVICE (Table 1 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'TRANSFORMED_DELIVERED_SERVICE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.CONSOLIDATED_CLAIM (Table of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CONSOLIDATED_CLAIM', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.POSTAL_ADDRESS (Table 3 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'POSTAL_ADDRESS', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.OPS_VALUE_REFERENCE (Table 4 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OPS_VALUE_REFERENCE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.GENERIC_REFERENCE (Table 5 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'GENERIC_REFERENCE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.AUDIT_LOG_ENTRY (Table 6 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'AUDIT_LOG_ENTRY', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.ORGANIZATION_INFORMATION (Table 7 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ORGANIZATION_INFORMATION', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PAYEE (Table 8 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYEE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.OFFSET_RECEIVABLE (Table 9 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OFFSET_RECEIVABLE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PRACTITIONER_CORRESPONDENCE (Table 10 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER_CORRESPONDENCE', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PAYMENT_STATUS_HISTORY (Table 11 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_STATUS_HISTORY', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.SUBSCRIPTION_PLAN_SELECTION (Table 12 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION_PLAN_SELECTION', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.UDT_VALUE_LINK (Table 13 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'UDT_VALUE_LINK', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.MEMBER_LINK (Table 14 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_LINK', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.CAPITATED_RECEIVABLE (Table 15 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CAPITATED_RECEIVABLE', degree=>3, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.FEE_DETAIL (Table 16 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FEE_DETAIL', degree=>6, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.PRACTITIONER_MEMBER (Table 17 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER_MEMBER', degree=>6, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.PRACTITIONER (Table 18 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER', degree=>4, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.PRACTITIONER_ROLE (Table 19 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER_ROLE', degree=>4, cascade=>true, force=>true);
prompt


prompt
prompt Gathering Stats on Table PROD.NAMED_PROVIDER_GROUPING (Table 20 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'NAMED_PROVIDER_GROUPING', degree=>6, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.IDENTIFICATION_NUMBER (Table 21 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'IDENTIFICATION_NUMBER', degree=>4, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.SUPPLIER_X_OTHER_ID_LIST (Table 22 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_X_OTHER_ID_LIST', degree=>4, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.PERSON_NAME (Table 23 of 23);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PERSON_NAME', degree=>6, cascade=>true, force=>true);
prompt


set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

