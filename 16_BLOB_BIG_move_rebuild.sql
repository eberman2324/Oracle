set line 140 trimspool on head on echo off pagesize 999 feed off

col name for a30
col type for a5
col ts for a5


spool 16_BLOB_BIG_move_rebuild.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on
set echo on timing on head off

-- BL_CONSLTD_CLM_U_ED_SERV_DEF
--Move LOB to DATA3 - 1.4 TB
--prompt Moving LOB 
--ALTER TABLE PROD.BL_CONSLTD_CLM_U_ED_SERV_DEF MOVE LOB(SERIAL_INST_BLOB) STORE AS SECUREFILE  /*SYS_LOB0000295636C00002$$*/ (TABLESPACE DATA3) PARALLEL 28;
--prompt

-- Move Table to new DATA3 tbs
prompt Moving Table;
ALTER TABLE PROD.BL_CONSLTD_CLM_U_ED_SERV_DEF MOVE TABLESPACE DATA3 NOLOGGING PARALLEL 28;
ALTER TABLE PROD.BL_CONSLTD_CLM_U_ED_SERV_DEF LOGGING NOPARALLEL;
prompt


--Rebuild index to INDX5 tbs
prompt Rebuilding (Index 1 of 2);
ALTER INDEX PROD.BL_CONSLTD_CLM_U_ED_SERV_DEF REBUILD NOLOGGING PARALLEL 28 TABLESPACE INDX5;
ALTER INDEX PROD.BL_CONSLTD_CLM_U_ED_SERV_DEF LOGGING NOPARALLEL;
prompt

--Rebuild index to INDX5 tbs
prompt Rebuilding (Index 1 of 2);
ALTER INDEX PROD.CONSLTD_CLM_U_ED_SERV_DEF_ITS REBUILD NOLOGGING PARALLEL 28 TABLESPACE INDX5;
ALTER INDEX PROD.CONSLTD_CLM_U_ED_SERV_DEF_ITS LOGGING NOPARALLEL;
prompt

set echo off timing off head on feed on
set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

