set echo off feed off verify off line 140 termout on sqlblanklines on head on trimspool on

spool gather_cap_&1..out


select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

column table_name format a40
column owner    format a12
select  owner, table_name, LAST_ANALYZED, num_rows, temporary from dba_tables
where table_name in
('ATTRIBUTION_LINE','RECONCILIATION_LINE','SPECIALTY_NETWORK_LINK')
        and owner = 'PROD'
        and temporary = 'N'
order by 4 desc
;


set head off timing on

prompt

prompt Gathering Stats on Table PROD.ATTRIBUTION_LINE (Table 1 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ATTRIBUTION_LINE', degree=>6, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.RECONCILIATION_LINE (Table 2 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECONCILIATION_LINE', degree=>6, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SPECIALTY_NETWORK_LINK (Table 3 of 3);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPECIALTY_NETWORK_LINK', degree=>6, cascade=>true);
prompt

set head on timing off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

column table_name format a40
column owner    format a12
select  owner, table_name, LAST_ANALYZED, num_rows, temporary from dba_tables
where table_name in
('ATTRIBUTION_LINE','RECONCILIATION_LINE','SPECIALTY_NETWORK_LINK')
        and owner = 'PROD'
        and temporary = 'N'
order by 4 desc
;

spool off ;

