set line 140 trimspool on head on echo off pagesize 999 feed off

col name for a30
col type for a5
col ts for a5

spool redef_rebuilds.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on
set echo on timing on head off

-- PROD.PRACT_MBR
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (PRACT_MBR);
ALTER INDEX PROD.PRACT_MBR REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.PRACT_MBR LOGGING NOPARALLEL;
prompt


-- FK_PR_MBR_NAMED_PRV_GROUPING
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FK_PR_MBR_NAMED_PRV_GROUPING);
ALTER INDEX PROD.FK_PR_MBR_NAMED_PRV_GROUPING REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FK_PR_MBR_NAMED_PRV_GROUPING LOGGING NOPARALLEL;
prompt


-- FK_PRACT_MBR_PRACT
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FK_PRACT_MBR_PRACT);
ALTER INDEX PROD.FK_PRACT_MBR_PRACT REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FK_PRACT_MBR_PRACT LOGGING NOPARALLEL;
prompt


-- ID_NUM_NOUPPER_NBR
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (ID_NUM_NOUPPER_NBR);
ALTER INDEX PROD.ID_NUM_NOUPPER_NBR REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.ID_NUM_NOUPPER_NBR LOGGING NOPARALLEL;
prompt

-- ID_NUM_UPPER_NBR
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (ID_NUM_UPPER_NBR);
ALTER INDEX PROD.ID_NUM_UPPER_NBR REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.ID_NUM_UPPER_NBR LOGGING NOPARALLEL;
prompt

-- VIDDATES_FEE_DETAIL
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (VIDDATES_FEE_DETAIL);
ALTER INDEX PROD.VIDDATES_FEE_DETAIL REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.VIDDATES_FEE_DETAIL LOGGING NOPARALLEL;
prompt


-- FEE_TABLE_SERV_CD
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FEE_TABLE_SERV_CD);
ALTER INDEX PROD.FEE_TABLE_SERV_CD REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FEE_TABLE_SERV_CD LOGGING NOPARALLEL;
prompt


-- FEE_TABLE_REV_CD
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FEE_TABLE_REV_CD);
ALTER INDEX PROD.FEE_TABLE_REV_CD REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FEE_TABLE_REV_CD LOGGING NOPARALLEL;
prompt
      
-- FEE_TABLE_UPPER_SERV_CD
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FEE_TABLE_UPPER_SERV_CD);
ALTER INDEX PROD.FEE_TABLE_UPPER_SERV_CD REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FEE_TABLE_UPPER_SERV_CD LOGGING NOPARALLEL;
prompt

-- PRACTITIONER_MEMBER_AEDBA_1
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (PRACTITIONER_MEMBER_AEDBA_1);
ALTER INDEX PROD.PRACTITIONER_MEMBER_AEDBA_1 REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.PRACTITIONER_MEMBER_AEDBA_1 LOGGING NOPARALLEL;
prompt

-- IDENT_NBR
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (IDENT_NBR);
ALTER INDEX PROD.IDENT_NBR REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.IDENT_NBR LOGGING NOPARALLEL;
prompt

-- FK_SPPLR_X_SP_CLASS_TYPE_SPP
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FK_SPPLR_X_SP_CLASS_TYPE_SPP);
ALTER INDEX PROD.FK_SPPLR_X_SP_CLASS_TYPE_SPP REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FK_SPPLR_X_SP_CLASS_TYPE_SPP LOGGING NOPARALLEL;
prompt
                             

-- SPPLR_X_SPPLR_CLASS_TYPE
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (SPPLR_X_SPPLR_CLASS_TYPE);
ALTER INDEX PROD.SPPLR_X_SPPLR_CLASS_TYPE REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.SPPLR_X_SPPLR_CLASS_TYPE LOGGING NOPARALLEL;
prompt

-- VER_ID_ADDR_ZIP_AEDBA_1
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (VER_ID_ADDR_ZIP_AEDBA_1);
ALTER INDEX PROD.VER_ID_ADDR_ZIP_AEDBA_1 REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.VER_ID_ADDR_ZIP_AEDBA_1 LOGGING NOPARALLEL;
prompt

-- PKDATES_FEE_DETAIL
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (PKDATES_FEE_DETAIL);
ALTER INDEX PROD.PKDATES_FEE_DETAIL REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.PKDATES_FEE_DETAIL LOGGING NOPARALLEL;
prompt


-- FK_OPS_VAL_REF_CVC_STEP
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FK_OPS_VAL_REF_CVC_STEP);
ALTER INDEX PROD.FK_OPS_VAL_REF_CVC_STEP REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FK_OPS_VAL_REF_CVC_STEP LOGGING NOPARALLEL;
prompt


-- FK_IDENT_NBR_CD_ENTRY
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (FK_IDENT_NBR_CD_ENTRY);
ALTER INDEX PROD.FK_IDENT_NBR_CD_ENTRY REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.FK_IDENT_NBR_CD_ENTRY LOGGING NOPARALLEL;
prompt



-- OPS_VAL_REF
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (OPS_VAL_REF);
ALTER INDEX PROD.OPS_VAL_REF REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.OPS_VAL_REF LOGGING NOPARALLEL;
prompt


-- ADDR_ZIP_UP_IDX
--Rebuild index to PROD_INDEX tbs
prompt Rebuilding (ADDR_ZIP_UP_IDX);
ALTER INDEX PROD.ADDR_ZIP_UP_IDX REBUILD NOLOGGING PARALLEL 6 TABLESPACE PROD_INDEX;
ALTER INDEX PROD.ADDR_ZIP_UP_IDX LOGGING NOPARALLEL;
prompt


set echo off timing off head on feed on
set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

