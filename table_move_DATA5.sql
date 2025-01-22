set line 140 trimspool on head on echo off pagesize 999 feed off


col name for a30
col type for a5
col ts for a5

spool table_move_DATA5.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off

-- Took 

--460 G
prompt (Moving Table: UNMATCHED_DATE_RANGE)
ALTER TABLE  PROD.UNMATCHED_DATE_RANGE MOVE TABLESPACE DATA9 PARALLEL 18;
ALTER TABLE  PROD.UNMATCHED_DATE_RANGE NOPARALLEL;
prompt

--250 G was in INDX2
prompt (Rebuilding index:  FK_UNMAT_RANGE_UNMATCH_EF_REF)
ALTER INDEX PROD.FK_UNMAT_RANGE_UNMATCH_EF_REF REBUILD PARALLEL 20 TABLESPACE INDX2;
ALTER INDEX PROD.FK_UNMAT_RANGE_UNMATCH_EF_REF NOPARALLEL;
prompt


--240 G was in INDX2
prompt (Rebuilding index:  UNMATCHED_DATE_RANGE)
ALTER INDEX PROD.UNMATCHED_DATE_RANGE REBUILD PARALLEL 20 TABLESPACE INDX2;
ALTER INDEX PROD.UNMATCHED_DATE_RANGE NOPARALLEL;
prompt



set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
