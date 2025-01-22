col type for a5
col ts for a5

spool add_indexes_PERSON_NAME.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off



CREATE INDEX PROD.PERS_NM_1ST_NM_NORM
    ON PROD.PERSON_NAME("PROD"."NORMALIZE_STRING"("FIRST_NM")
)
TABLESPACE INDX5
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 167
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_1ST_NM_UP
    ON PROD.PERSON_NAME(UPPER("FIRST_NM")
)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_LAST_1ST
    ON PROD.PERSON_NAME(UPPER("LAST_NM"),
UPPER("FIRST_NM")
)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_LAST_1ST_CASE
    ON PROD.PERSON_NAME(LAST_NM,FIRST_NM)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_LAST_NM_NORM
    ON PROD.PERSON_NAME("PROD"."NORMALIZE_STRING"("LAST_NM")
)
TABLESPACE INDX5
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 167
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_LAST_NM_UP
    ON PROD.PERSON_NAME(UPPER("LAST_NM")
)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_MID_NM_NORM
    ON PROD.PERSON_NAME("PROD"."NORMALIZE_STRING"("MDDL_NM")
)
TABLESPACE INDX5
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 167
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE INDEX PROD.PERS_NM_PRFX_CD_NORM
    ON PROD.PERSON_NAME("PROD"."NORMALIZE_STRING"("PRFX_CD")
)
TABLESPACE INDX5
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 167
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/
CREATE UNIQUE INDEX PROD.PRSN_NAME_IDX
    ON PROD.PERSON_NAME(PERSON_NM_ID,LAST_NM,FIRST_NM,VER_ID)
TABLESPACE INDX4
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
PARALLEL 6
NOCOMPRESS
/






alter session set DDL_LOCK_TIMEOUT = 300;


ALTER INDEX PROD.PRSN_NAME_IDX NOPARALLEL;

ALTER INDEX PROD.PERS_NM_PRFX_CD_NORM NOPARALLEL;

ALTER INDEX PROD.PERS_NM_MID_NM_NORM NOPARALLEL;

ALTER INDEX PROD.PERS_NM_LAST_NM_UP NOPARALLEL;

ALTER INDEX PROD.PERS_NM_LAST_NM_NORM NOPARALLEL;

ALTER INDEX PROD.PERS_NM_LAST_1ST_CASE NOPARALLEL;

ALTER INDEX PROD.PERS_NM_LAST_1ST NOPARALLEL;

ALTER INDEX PROD.PERS_NM_1ST_NM_UP NOPARALLEL;

ALTER INDEX PROD.PERS_NM_1ST_NM_NORM NOPARALLEL;



set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
