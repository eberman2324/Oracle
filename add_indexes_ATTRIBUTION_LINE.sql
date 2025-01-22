col type for a5
col ts for a5

spool add_indexes_ATTRIBUTION_LINE.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off



CREATE INDEX PROD.ATTR_LN_PREM_REC_ISRECNCLD_IDX
ON PROD.ATTRIBUTION_LINE(BILLING_ACCT_ACCT_ID,PREM_RECEIVABLE_ID,IS_RECONCILED_IND)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LINE_ACCOUNT
    ON PROD.ATTRIBUTION_LINE(ACCT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LINE_BILL
    ON PROD.ATTRIBUTION_LINE(BILL_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LINE_CODE_ENTRY
    ON PROD.ATTRIBUTION_LINE(CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LINE_MEMBERSHIP
    ON PROD.ATTRIBUTION_LINE(MBRSHP_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LINE_PRODUCT
    ON PROD.ATTRIBUTION_LINE(PROD_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LN_BILL_SECTION
    ON PROD.ATTRIBUTION_LINE(BILL_SECTION_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LN_BNFT_PLAN
    ON PROD.ATTRIBUTION_LINE(BNFT_PLAN_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LN_COV_TIER
    ON PROD.ATTRIBUTION_LINE(COV_TIER_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LN_COV_TIER_SET
    ON PROD.ATTRIBUTION_LINE(COV_TIER_SET_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LN_PREM_BILL_LN
    ON PROD.ATTRIBUTION_LINE(PREM_BILL_LN_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LN_PREM_PAYABLE
    ON PROD.ATTRIBUTION_LINE(PREM_PAYABLE_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRIBUTION_LN_PREM_PAYMNT
    ON PROD.ATTRIBUTION_LINE(PAYMNT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATTRIBUTION_LN_SUBSCRP
    ON PROD.ATTRIBUTION_LINE(SUBSCRP_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRI_ION_LN_BILLING_DJUST
    ON PROD.ATTRIBUTION_LINE(BILLING_ADJUST_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRI_ION_LN_PREM_RE_VABLE
    ON PROD.ATTRIBUTION_LINE(PREM_RECEIVABLE_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRI_ION_LN_PREM_SU_DY_LN
    ON PROD.ATTRIBUTION_LINE(PREM_SUBSIDY_LN_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRI_ON_LN_AC_BILLI_ACCT
    ON PROD.ATTRIBUTION_LINE(BILLING_ACCT_ACCT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTRI_ON_LN_BI_BILL_CTION
    ON PROD.ATTRIBUTION_LINE(BILL_SECTION_BILL_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_N_LN_BILLING_C_SECTION
    ON PROD.ATTRIBUTION_LINE(BILLING_CAT_BILL_SECTION_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_N_LN_BNFT_PLA_SECTION
    ON PROD.ATTRIBUTION_LINE(BNFT_PLAN_BILL_SECTION_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_N_LN_CURRENT_B_ATE_LN
    ON PROD.ATTRIBUTION_LINE(CURRENT_LN_LN_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_N_LN_PREM_PAYM_R_ENTRY
    ON PROD.ATTRIBUTION_LINE(ROSTER_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_N_LN_SUB_P_BILLIN_CRP
    ON PROD.ATTRIBUTION_LINE(BILLING_SUBSCRP_SUBSCRP_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_ON_LN_CD_TRY_BILLI_AT
    ON PROD.ATTRIBUTION_LINE(BILLING_CAT_CD_ENTRY_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATTR_ON_LN_OTHR_BIL_IPIENT
    ON PROD.ATTRIBUTION_LINE(OTHR_BILL_RECIPIENT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.FK_ATT_LN_PREM_LN_I_ON_INPUT
    ON PROD.ATTRIBUTION_LINE(INPUT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_ATT_N_LN_RETROACTI_RATE_LN
    ON PROD.ATTRIBUTION_LINE(RETRO_LN_LN_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;

CREATE INDEX PROD.FK_AT_LN_PRE_T_SRC_PAY_IBTION
    ON PROD.ATTRIBUTION_LINE(SRC_PAYMNT_ATTRIBTION_PA_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;


CREATE INDEX PROD.TENANTID_ATTRIBUTION_LN
    ON PROD.ATTRIBUTION_LINE(TENANT_ID)
TABLESPACE INDX5 ONLINE PARALLEL 6;








alter session set DDL_LOCK_TIMEOUT = 300;

ALTER INDEX PROD.TENANTID_ATTRIBUTION_LN NOPARALLEL;

ALTER INDEX PROD.FK_AT_LN_PRE_T_SRC_PAY_IBTION NOPARALLEL;

ALTER INDEX PROD.FK_ATT_N_LN_RETROACTI_RATE_LN NOPARALLEL;
 
ALTER INDEX PROD.FK_ATT_LN_PREM_LN_I_ON_INPUT NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_ON_LN_OTHR_BIL_IPIENT NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_ON_LN_CD_TRY_BILLI_AT NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_N_LN_SUB_P_BILLIN_CRP NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_N_LN_PREM_PAYM_R_ENTRY NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_N_LN_CURRENT_B_ATE_LN NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_N_LN_BNFT_PLA_SECTION NOPARALLEL;

ALTER INDEX PROD.FK_ATTR_N_LN_BILLING_C_SECTION NOPARALLEL;

ALTER INDEX PROD.FK_ATTRI_ON_LN_BI_BILL_CTION NOPARALLEL;

ALTER INDEX PROD.FK_ATTRI_ON_LN_AC_BILLI_ACCT NOPARALLEL;

ALTER INDEX PROD.FK_ATTRI_ION_LN_PREM_SU_DY_LN NOPARALLEL;

ALTER INDEX PROD.FK_ATTRI_ION_LN_PREM_RE_VABLE NOPARALLEL;

ALTER INDEX PROD.FK_ATTRI_ION_LN_BILLING_DJUST NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_SUBSCRP NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_PREM_PAYMNT NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_PREM_PAYABLE NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_PREM_BILL_LN NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_COV_TIER_SET NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_COV_TIER NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_BNFT_PLAN NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LN_BILL_SECTION NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LINE_PRODUCT NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LINE_MEMBERSHIP NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LINE_CODE_ENTRY NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LINE_BILL NOPARALLEL;

ALTER INDEX PROD.FK_ATTRIBUTION_LINE_ACCOUNT NOPARALLEL;

ALTER INDEX PROD.ATTR_LN_PREM_REC_ISRECNCLD_IDX NOPARALLEL;




set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
