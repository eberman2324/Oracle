set line 140 trimspool on head on echo off pagesize 999 feed off

col name for a30
col type for a5
col ts for a5

spool move_AUDIT_LOG_ENTRY.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on

select segment_name Name, segment_type Type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s
where s.segment_name = 'AUDIT_LOG_ENTRY'
and   s.segment_type = 'TABLE'
and   s.owner        = 'PROD'
union all
select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
and   i.table_name   = 'AUDIT_LOG_ENTRY'
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD'
order by 3 desc;

set echo on timing on head off




-- 875 G in HEPYMASK (took 20 min fast archivelog generation. Watch out for space!!)
-- 972 G in HEPYPRD
prompt Moving Table;
ALTER TABLE PROD.AUDIT_LOG_ENTRY MOVE TABLESPACE DATA9 PARALLEL 18;
ALTER TABLE PROD.AUDIT_LOG_ENTRY NOPARALLEL;
prompt

--took almost 4 hours in HEPYMASK 
-- 415 G HEPYPRD
prompt Rebuilding (Index 1 of 10);
ALTER INDEX PROD.AUDIT_LOG_ENTRY_ID_SUBTYPENM REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.AUDIT_LOG_ENTRY_ID_SUBTYPENM NOPARALLEL;
prompt

-- 388 G HEPYPRD
prompt Rebuilding (Index 2 of 10);
ALTER INDEX PROD.AUDIT_LOG_ENTRY_CVCID_NM_ID REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.AUDIT_LOG_ENTRY_CVCID_NM_ID NOPARALLEL;
prompt

-- 220 G HEPYPRD
prompt Rebuilding (Index 3 of 10);
ALTER INDEX PROD.ENTRY_TIME_IDX REBUILD PARALLEL 20 TABLESPACE INDX5;
ALTER INDEX PROD.ENTRY_TIME_IDX NOPARALLEL;
prompt

-- 170 G HEPYPRD
prompt Rebuilding (Index 4 of 10);
ALTER INDEX PROD.AUDIT_LOG_ENTRY REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.AUDIT_LOG_ENTRY NOPARALLEL;
prompt

-- 165 G HEPYPRD
prompt Rebuilding (Index 5 of 10);
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_AUDIT_LOG REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_AUDIT_LOG NOPARALLEL;
prompt

-- 90 G HEPYPRD
prompt Rebuilding (Index 6 of 10);
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_GEN_VER_REF REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_GEN_VER_REF NOPARALLEL;
prompt


-- 80 G HEPYPRD
prompt Rebuilding (Index 7 of 10);
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_MSG_CD REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_MSG_CD NOPARALLEL;
prompt

-- 70 G HEPYPRD
prompt Rebuilding (Index 8 of 10);
ALTER INDEX PROD.AUDLOGENT_CVC_ID REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.AUDLOGENT_CVC_ID NOPARALLEL;
prompt

-- 2 G HEPYPRD
prompt Rebuilding (Index 9 of 10);
ALTER INDEX PROD.FK_AUDIT_ENTRY_TRIGGER_INFO REBUILD PARALLEL 20 TABLESPACE INDX4;
ALTER INDEX PROD.FK_AUDIT_ENTRY_TRIGGER_INFO NOPARALLEL;
prompt

-- 2 G HEPYPRD
prompt Rebuilding (Index 10 of 10);
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_CODE_ENTRY REBUILD PARALLEL 18 TABLESPACE INDX7;
ALTER INDEX PROD.FK_AUDIT_LOG_ENTRY_CODE_ENTRY NOPARALLEL;
prompt


set echo off timing off head on feed on

select segment_name Name, segment_type Type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s
where s.segment_name = 'AUDIT_LOG_ENTRY'
and   s.segment_type = 'TABLE'
and   s.owner        = 'PROD'
union all
select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
and   i.table_name   = 'AUDIT_LOG_ENTRY'
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD'
order by 3 desc;

set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

