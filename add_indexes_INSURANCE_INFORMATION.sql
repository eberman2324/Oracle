col type for a5
col ts for a5

spool add_indexes_INSURANCE_INFORMATION.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off


CREATE INDEX PROD.FK_INSURANCE_INFORMATION_UB92
    ON PROD.INSURANCE_INFORMATION(QXJ__PARENT)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_IN_NFO_SPPLR_INV_MENTED_NM
    ON PROD.INSURANCE_INFORMATION(SPPLR_INV_SEGMENTED_NM_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;






alter session set DDL_LOCK_TIMEOUT = 300;

ALTER INDEX PROD.FK_INSURANCE_INFORMATION_UB92 NOPARALLEL;
ALTER INDEX PROD.FK_IN_NFO_SPPLR_INV_MENTED_NM NOPARALLEL;


set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
