set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_claim_lines_for_sub_&1..out

prompt Script name: gather_claim_lines_for_sub.sql


select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on


prompt
prompt Gathering Stats on Table PROD.PLACE_OF_SERVICE (Table 1 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PLACE_OF_SERVICE', cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.TYPE_OF_BILL (Table 2 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'TYPE_OF_BILL', cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.SERVICE (Table 3 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SERVICE', degree=>2, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.SUBSCRIPTION (Table 4 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION', degree=>4, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.BLUE_CARD_SF_CONSLTD_LN_INFO (Table 5 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BLUE_CARD_SF_CONSLTD_LN_INFO', cascade=>true, force=>true);
prompt



prompt
prompt Gathering Stats on Table PROD.PRODUCT (Table 6 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRODUCT', cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.BENEFIT_PLAN (Table 7 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BENEFIT_PLAN', cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.SERVICE_COST (Table 8 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SERVICE_COST', degree=>4, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.ACCOUNT (Table 9 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ACCOUNT', cascade=>true, force=>true);
prompt





prompt
prompt Gathering Stats on Table PROD.SUPPLIER_INVOICE (Table 10 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_INVOICE', degree=>4, cascade=>true, force=>true);
prompt

prompt
prompt Gathering Stats on Table PROD.BENEFIT (Table 11 of 11);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BENEFIT', degree=>4, cascade=>true, force=>true);
prompt







set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

