set echo off feed off verify off line 140 termout on trimspool on sqlblanklines on head on

spool gather_he_paycalc1_&1..out


prompt Script name: gather_he_paycalc1.sql




select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set head off timing on

prompt
prompt Gathering Stats on Table PROD.OUTSTANDING_PAYABLE (Table 1 of 2);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OUTSTANDING_PAYABLE', degree=>4, cascade=>true, force=>true);
prompt


prompt
prompt Gathering Stats on Table PROD.PAYABLE (Table 2 of 2);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYABLE', degree=>6, cascade=>true, force=>true);
prompt


set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

!chmod 600 *.out

