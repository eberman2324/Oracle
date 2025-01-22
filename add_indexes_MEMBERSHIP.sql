col type for a5
col ts for a5

spool add_indexes_MEMBERSHIP.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off

CREATE INDEX PROD.ALIAS_MBRSHP
    ON PROD.MEMBERSHIP(UPPER("HCC_ID"),
TENANT_ID,
CONCEPT_FULFILLED_CD,
VER_EFF_DT,
VER_EXPIRE_DT,
ENDOR_EFF_DT,
ENDOR_EXPIRE_DT
)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MBRSHP_CD_ENTRY_EMAIL_FRMT
    ON PROD.MEMBERSHIP(EMAIL_FRMT_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBRSHP_CD_ENTRY_EMP_TYPE
    ON PROD.MEMBERSHIP(EMP_TYPE_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MBRSHP_CD_ENTRY_INFO_SRC
    ON PROD.MEMBERSHIP(INFO_SRC_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBRSHP_CD_ENTRY_VIP_RSN
    ON PROD.MEMBERSHIP(VIP_RSN_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBRSHP_INDVL_INFO
    ON PROD.MEMBERSHIP(INDVL_INFO_ID,VER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBRSHP_MBR_DENT_INFO
    ON PROD.MEMBERSHIP(MBR_DENT_INFO_ID,VER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBRSHP_RLTP_TO_SUBSCRB_DEF
    ON PROD.MEMBERSHIP(RLTP_TO_SUBSCRB_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_MBR_SUB_DATES
    ON PROD.MEMBERSHIP(SUBSCRP_ID,CONCEPT_FULFILLED_CD,VER_EFF_DT,VER_EXPIRE_DT,ENDOR_EFF_DT,ENDOR_EXPIRE_DT)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MB_HP_CD_E_RY_DENIAL_SN_CD
    ON PROD.MEMBERSHIP(DENIAL_RSN_CD_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MB_HP_CD_E_RY_REDUCTI_RSN
    ON PROD.MEMBERSHIP(REDUCTION_RSN_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_ATTACHMENT_SET
    ON PROD.MEMBERSHIP(ATTACHMENT_SET_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_AUDIT_LOG
    ON PROD.MEMBERSHIP(AUDIT_LOG_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_CODE_ENTRY
    ON PROD.MEMBERSHIP(CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_CODE_ENTRY_UNITS
    ON PROD.MEMBERSHIP(UNITS_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_DEPARTMENT
    ON PROD.MEMBERSHIP(DEPART_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_DIAGNOSIS
    ON PROD.MEMBERSHIP(DIAG_CD)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_INDIVIDUAL
    ON PROD.MEMBERSHIP(INDVL_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_MEMBERSHIP
    ON PROD.MEMBERSHIP(SUBSCRB_MBRSHP_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_PERSON_NAME
    ON PROD.MEMBERSHIP(PERSON_NM_ID,VER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_POSTAL_ADDRESS
    ON PROD.MEMBERSHIP(POSTAL_ADDR_ID,VER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_MEMBERSHIP_SUBSCRIPTION
    ON PROD.MEMBERSHIP(SUBSCRP_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_M_HP_CD_E_RY_HLTH_ST_S_RSN
    ON PROD.MEMBERSHIP(HLTH_STATUS_RSN_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_M_HP_CD_E_RY_SALARY_ADE_CD
    ON PROD.MEMBERSHIP(SALARY_GRADE_CD_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_M_HP_CD_TRY_EMPMNT_TUS_CD
    ON PROD.MEMBERSHIP(EMPMNT_STATUS_CD_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_M_HP_POSTA_DDR_RECIPI_ADDR
    ON PROD.MEMBERSHIP(RECIPIENT_ADDR_POSTAL_ADDR_ID,VER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE UNIQUE INDEX PROD.MBRSHP_SUBS_INDX
    ON PROD.MEMBERSHIP(MBRSHP_ID,HCC_ID,VER_ID,SUBSCRP_ID,INDVL_INFO_ID,RLTP_TO_SUBSCRB_ID)
TABLESPACE INDX4 ONLINE PARALLEL 6;

CREATE INDEX PROD.MBR_PAYEE_HCC_ID
    ON PROD.MEMBERSHIP(PAYEE_HCC_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.MEMBERSHIP_AEDBA_1
    ON PROD.MEMBERSHIP(MBRSHP_ID,CONCEPT_FULFILLED_CD,ENDOR_EXPIRE_DT,ENDOR_EFF_DT,VER_EXPIRE_DT,VER_EFF_DT)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.MEMBERSHIP_CONCEPT_FULFIL_IDX
    ON PROD.MEMBERSHIP(CONCEPT_FULFILLED_CD,MBRSHP_ID,ENDOR_EXPIRE_DT,TX_CNT)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.MEMBER_HCC_ID
    ON PROD.MEMBERSHIP(HCC_ID,CONCEPT_FULFILLED_CD,VER_EFF_DT,VER_EXPIRE_DT,ENDOR_EFF_DT,ENDOR_EXPIRE_DT)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE UNIQUE INDEX PROD.PKDATES_MBRSHP
    ON PROD.MEMBERSHIP(MBRSHP_ID,CONCEPT_FULFILLED_CD,VER_EFF_DT,VER_EXPIRE_DT,ENDOR_EFF_DT,ENDOR_EXPIRE_DT)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.TENANTID_MBRSHP
    ON PROD.MEMBERSHIP(TENANT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.VIDDATES_MBRSHP
    ON PROD.MEMBERSHIP(VER_ID,CONCEPT_FULFILLED_CD,VER_EFF_DT,VER_EXPIRE_DT,ENDOR_EFF_DT,ENDOR_EXPIRE_DT)
TABLESPACE INDX5 ONLINE PARALLEL 6;


alter session set DDL_LOCK_TIMEOUT = 300;


ALTER INDEX PROD.VIDDATES_MBRSHP NOPARALLEL;

ALTER INDEX PROD.TENANTID_MBRSHP NOPARALLEL;

ALTER INDEX PROD.PKDATES_MBRSHP NOPARALLEL;

ALTER INDEX PROD.MEMBER_HCC_ID NOPARALLEL;

ALTER INDEX PROD.MEMBERSHIP_CONCEPT_FULFIL_IDX NOPARALLEL;

ALTER INDEX PROD.MEMBERSHIP_AEDBA_1 NOPARALLEL;

ALTER INDEX PROD.MBR_PAYEE_HCC_ID NOPARALLEL;

ALTER INDEX PROD.MBRSHP_SUBS_INDX NOPARALLEL;
 
ALTER INDEX PROD.FK_M_HP_POSTA_DDR_RECIPI_ADDR NOPARALLEL;

ALTER INDEX PROD.FK_M_HP_CD_TRY_EMPMNT_TUS_CD NOPARALLEL;

ALTER INDEX PROD.FK_M_HP_CD_E_RY_SALARY_ADE_CD NOPARALLEL;

ALTER INDEX PROD.FK_M_HP_CD_E_RY_HLTH_ST_S_RSN NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_SUBSCRIPTION NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_POSTAL_ADDRESS NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_PERSON_NAME NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_MEMBERSHIP NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_INDIVIDUAL NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_DIAGNOSIS NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_DEPARTMENT NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_CODE_ENTRY_UNITS NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_CODE_ENTRY NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_AUDIT_LOG NOPARALLEL;

ALTER INDEX PROD.FK_MEMBERSHIP_ATTACHMENT_SET NOPARALLEL;

ALTER INDEX PROD.FK_MB_HP_CD_E_RY_REDUCTI_RSN NOPARALLEL;

ALTER INDEX PROD.FK_MB_HP_CD_E_RY_DENIAL_SN_CD NOPARALLEL;

ALTER INDEX PROD.FK_MBR_SUB_DATES NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_RLTP_TO_SUBSCRB_DEF NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_MBR_DENT_INFO NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_INDVL_INFO NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_CD_ENTRY_VIP_RSN NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_CD_ENTRY_INFO_SRC NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_CD_ENTRY_EMP_TYPE NOPARALLEL;

ALTER INDEX PROD.FK_MBRSHP_CD_ENTRY_EMAIL_FRMT NOPARALLEL;

ALTER INDEX PROD.ALIAS_MBRSHP NOPARALLEL;



set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
