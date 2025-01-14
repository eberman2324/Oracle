set echo off feed off verify off line 140 termout on trimspool on sqlblanklines on head on

spool gather_he_stats_&1..out


prompt Script name: gather_he_stats.sql

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on




prompt Gathering Stats on Table PROD.ACCOUNT_SELECTION (Table 1 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ACCOUNT_SELECTION', degree=>4, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.ADJUSTMENT_PAYABLE (Table 2 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ADJUSTMENT_PAYABLE', degree=>4, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.CLAIM_PAYABLE (Table 3 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_PAYABLE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.CLAIM_RECEIVABLE (Table 4 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_RECEIVABLE', degree=>3, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.COUNT_VALUE (Table 5 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'COUNT_VALUE', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.DIAGNOSIS (Table 6 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'DIAGNOSIS', degree=>3, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.EXCLUSION_SCHEDULE (Table 7 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'EXCLUSION_SCHEDULE', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.FEE_TABLE_CALCULATION_METHOD (Table 8 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'FEE_TABLE_CALCULATION_METHOD', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.HCFA1500_X_OTHER_DATES (Table 9 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'HCFA1500_X_OTHER_DATES', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.INCLUDED_PAYABLE (Table 10 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INCLUDED_PAYABLE', degree=>6, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.INDIVIDUAL (Table 11 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INDIVIDUAL', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.INTER_SERV_AUTH_X_EXCPT_LST (Table 12 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INTER_SERV_AUTH_X_EXCPT_LST', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.LIMIT (Table 13 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'LIMIT', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.MANUAL_RECEIVABLE (Table 14 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MANUAL_RECEIVABLE', degree=>3, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.NAMED_PRV_GROUPING_X_EXCPT_ST (Table 15 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'NAMED_PRV_GROUPING_X_EXCPT_ST', degree=>6, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.OTHER_DATE (Table 16 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OTHER_DATE', degree=>3, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.PAYEE_BANK_ACCOUNTS (Table 17 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYEE_BANK_ACCOUNTS', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PAYEE_BANK_ACCOUNT_DATE_RANGE (Table 18 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYEE_BANK_ACCOUNT_DATE_RANGE', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PAYMENT (Table 19 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT', degree=>4, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.RECEIVABLE (Table 20 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECEIVABLE', degree=>3, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.RECEIVABLE_RECOUPMENT (Table 21 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECEIVABLE_RECOUPMENT', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.RECEIVED_PAYMENT (Table 22 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECEIVED_PAYMENT', degree=>3, cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.RECOUPMENT_PAYMENT (Table 23 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECOUPMENT_PAYMENT', degree=>3, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.SUBSCRIPTION_SELECTIONS (Table 24 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION_SELECTIONS', degree=>4, cascade=>true, force=>true);
prompt



prompt Gathering Stats on Table PROD.TAX_ENTITY (Table 25 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'TAX_ENTITY', degree=>3, cascade=>true, force=>true);
prompt




prompt Gathering Stats on Table PROD.PROVIDER_TAXONOMY (Table 26 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PROVIDER_TAXONOMY', degree=>2, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.MEMBER_PLAN_SELECTION (Table 27 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_PLAN_SELECTION', degree=>4, cascade=>true, force=>true);
prompt


prompt Gathering Stats on Table PROD.CYCLE (Table 28 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CYCLE', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.PAYMENT_CYCLE (Table 29 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_CYCLE', cascade=>true, force=>true);
prompt

prompt Gathering Stats on Table PROD.BANK_ACCOUNT (Table 30 of 30);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BANK_ACCOUNT', cascade=>true, force=>true);
prompt



set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

!chmod 600 *.out

