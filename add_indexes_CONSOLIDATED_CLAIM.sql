col type for a5
col ts for a5

spool add_indexes_CONSOLIDATED_CLAIM.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off



CREATE INDEX PROD.CC_AEDBA_3
    ON PROD.CONSOLIDATED_CLAIM(SUBMITTED_S_IBER_INFO_ID_NBR,TYPE_OF_BILL_CD,SUBMITTED_SUBCRIBER_INFO_IND)
TABLESPACE INDX4
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_AEDBA_4
    ON PROD.CONSOLIDATED_CLAIM(CONSLTD_INPUT_PROCESSING_DT)
TABLESPACE INDX4
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_CLEAR_TRACE_NBR
    ON PROD.CONSOLIDATED_CLAIM(CONSLT_PUT_CLEARIN_TRACE_NBR)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_EXT_BATCH_NBR
    ON PROD.CONSOLIDATED_CLAIM(UPPER("CONSLT_PUT_EXTERNA_BATCH_NBR")
)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_EXT_CLAIM_NUMBER
    ON PROD.CONSOLIDATED_CLAIM(CONSLTD_INPUT_EXTERNAL_CLM_NBR)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_EXT_EF_CLAIM_NBR
    ON PROD.CONSOLIDATED_CLAIM(CONSL_PUT_EXTERNAL_EF_CLM_NBR,CONSLTD_INPUT_IND)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_HCC_CLM_NBR
    ON PROD.CONSOLIDATED_CLAIM(HCC_CLM_NBR,IS_REPLACED_IND)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_HCC_CLM_NBR_UP
    ON PROD.CONSOLIDATED_CLAIM(UPPER("HCC_CLM_NBR"),
IS_REPLACED_IND
)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_RECEIPT_DATE
    ON PROD.CONSOLIDATED_CLAIM(CONSLTD_INPUT_RECPT_DT)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/
CREATE INDEX PROD.CC_STATE_ENDOR_DT
    ON PROD.CONSOLIDATED_CLAIM(CLM_STATE_TXT,ENDOR_EFF_DT,ENDOR_EXPIRE_DT)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.CC_UNRESOLVED_REPROCESS
    ON PROD.CONSOLIDATED_CLAIM(CLM_STATE_TXT,IS_REPLACED_IND,MANUALLY_PRICED_IND,CONSLTD_INPUT_IS_CONVERTED_IND)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_ATTACHMENT_SET
    ON PROD.CONSOLIDATED_CLAIM(ATTACHMENT_SET_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_AUDIT_LOG
    ON PROD.CONSOLIDATED_CLAIM(AUDIT_LOG_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_CD_ENTRY
    ON PROD.CONSOLIDATED_CLAIM(CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_CLM_BATCH
    ON PROD.CONSOLIDATED_CLAIM(CLM_BATCH_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_CLM_TOTAL
    ON PROD.CONSOLIDATED_CLAIM(CLM_TOTAL_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_CONSLTD_CLM
    ON PROD.CONSOLIDATED_CLAIM(PREVIOUS_SLTD_CLM_CONSL_LM_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_DENT_CLM_INFO
    ON PROD.CONSOLIDATED_CLAIM(DENT_CLM_INFO_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_DIAG
    ON PROD.CONSOLIDATED_CLAIM(DIAG_CD)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/
CREATE INDEX PROD.FK_CONSLTD_CLM_DIAG_INFO
    ON PROD.CONSOLIDATED_CLAIM(DIAG_INFO_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_DISCHRG_STATUS
    ON PROD.CONSOLIDATED_CLAIM(DISCHRG_STATUS_CD)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_EXTERNAL_MBR
    ON PROD.CONSOLIDATED_CLAIM(EXTERNAL_MBR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_GEN_VER_REF
    ON PROD.CONSOLIDATED_CLAIM(GEN_REF_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_MBRSHP
    ON PROD.CONSOLIDATED_CLAIM(MBRSHP_ID,CLM_STATE_TXT,CONSLTD_INPUT_IS_CONVERTED_IND,IS_REPLACED_IND,MANUALLY_PRICED_IND,CONSLTD_INPUT_IND,CONSLTD_CLM_ID,HCC_CLM_NBR)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_PERSON_NM
    ON PROD.CONSOLIDATED_CLAIM(PERSON_NM_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_PHONE
    ON PROD.CONSOLIDATED_CLAIM(PHONE_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_PLACE_OF_SERV
    ON PROD.CONSOLIDATED_CLAIM(PLACE_OF_SERV_CD)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_POSTAL_ADDR
    ON PROD.CONSOLIDATED_CLAIM(POSTAL_ADDR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/
CREATE INDEX PROD.FK_CONSLTD_CLM_PRACT
    ON PROD.CONSOLIDATED_CLAIM(PRACT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_PROC_INFO
    ON PROD.CONSOLIDATED_CLAIM(PROC_INFO_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_PRVDR_TAXONOMY
    ON PROD.CONSOLIDATED_CLAIM(PRVDR_TAXONOMY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_SPPLR_INV
    ON PROD.CONSOLIDATED_CLAIM(SPPLR_INV_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_SPPLR_LOC
    ON PROD.CONSOLIDATED_CLAIM(SPPLR_LOC_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_SUBSCRP
    ON PROD.CONSOLIDATED_CLAIM(SUBSCRP_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSLTD_CLM_TYPE_OF_BILL
    ON PROD.CONSOLIDATED_CLAIM(TYPE_OF_BILL_CD)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSOLIDATED_CLAIM_DRG
    ON PROD.CONSOLIDATED_CLAIM(DRG_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONSOLIDATED_CLAIM_SUPPLIER
    ON PROD.CONSOLIDATED_CLAIM(SPPLR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONS_D_CLM_CD_E_RY_ADMS_RC
    ON PROD.CONSOLIDATED_CLAIM(ADMS_SRC_CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONS_D_CLM_CD_E_RY_CLM_RC
    ON PROD.CONSOLIDATED_CLAIM(CLM_SRC_CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONS_D_CLM_DR_DRG_OV_RIDE
    ON PROD.CONSOLIDATED_CLAIM(DRG_OVERRIDE_DRG_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONS_D_CLM_POSTAL_DDR_AD
    ON PROD.CONSOLIDATED_CLAIM(ADDR_POSTAL_ADDR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CONS_D_CLM_PRA_ATTND_RACT
    ON PROD.CONSOLIDATED_CLAIM(ATTND_PRACT_PRACT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_CD_TRY_ADMS_E_CD
    ON PROD.CONSOLIDATED_CLAIM(ADMS_TYPE_CD_CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_CD_TRY_BNFT_P_TYPE
    ON PROD.CONSOLIDATED_CLAIM(BNFT_PLAN_TYPE_CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_CD_TRY_DATE_L_CD
    ON PROD.CONSOLIDATED_CLAIM(DATE_QUAL_CD_CD_ENTRY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_DR_CALCULAT_RG_CD
    ON PROD.CONSOLIDATED_CLAIM(CALCULATED_DRG_CD_DRG_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_POSTA_DR_PAY_T_DR
    ON PROD.CONSOLIDATED_CLAIM(PAY_TO_ADDR_POSTAL_ADDR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_PRA_OPERATI_RACT
    ON PROD.CONSOLIDATED_CLAIM(OPERATING_PRACT_PRACT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_SPPLR_INV_NTED_NM
    ON PROD.CONSOLIDATED_CLAIM(SPPLR_INV_SEGMENTED_NM_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_CLM_SPPL_NV_CURREN_PUT
    ON PROD.CONSOLIDATED_CLAIM(CURRENT_INPUT_SPPLR_INV_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CON_D_CLM_CLM_TOTA_OR_PLAN
    ON PROD.CONSOLIDATED_CLAIM(CLM_TOTAL_FOR_PLAN_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_BLUE_CARD_ADER_INFO
    ON PROD.CONSOLIDATED_CLAIM(BLUE_CARD_SF_C_HEADER_INFO_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_BLUE_CARD_NG_RESULT
    ON PROD.CONSOLIDATED_CLAIM(BLUE_CARD_PROCESSING_RESULT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_CLM_DELEG_TRIBUTES
    ON PROD.CONSOLIDATED_CLAIM(CLM_DELEGATED_ATTRIBUTES_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_CONS_LM_PREVIO_TATE
    ON PROD.CONSOLIDATED_CLAIM(PREVIOUS_M_STATE_CONSL_CLM_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_POST_DR_RESPBL_ADDR
    ON PROD.CONSOLIDATED_CLAIM(RESPBL_P_Y_ADDR_POSTAL_DDR_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_PR_OTHR_OP_PRACT
    ON PROD.CONSOLIDATED_CLAIM(OTHR_OPERATING_PRACT_PRACT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_SPPL_C_RENDE_LOC
    ON PROD.CONSOLIDATED_CLAIM(RENDER_FAC_LOC_SPPLR_LOC_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_CO_CLM_SPPL_V_PREDET_TION
    ON PROD.CONSOLIDATED_CLAIM(PREDETERMINATION_SPPLR_INV_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_C_CLM_CD_Y_CALCULAT_N_TYPE
    ON PROD.CONSOLIDATED_CLAIM(CALCULATED_PLAN_TYPE_CD_RY_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.FK_C_CLM_SPPLR_I_ED_NM_SEGM_NM
    ON PROD.CONSOLIDATED_CLAIM(SEGME_NM_SPPLR_IN_NTED_NM_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
REVERSE
ONLINE PARALLEL 6 
NOCOMPRESS
/

CREATE INDEX PROD.TENANTID_CONSLTD_CLM
    ON PROD.CONSOLIDATED_CLAIM(TENANT_ID)
TABLESPACE INDX2
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
ONLINE PARALLEL 6 
NOCOMPRESS
/



alter session set DDL_LOCK_TIMEOUT = 300;





ALTER INDEX PROD.CC_AEDBA_3 NOPARALLEL;


ALTER INDEX PROD.CC_AEDBA_4 NOPARALLEL;


ALTER INDEX PROD.CC_CLEAR_TRACE_NBR NOPARALLEL;


ALTER INDEX PROD.CC_EXT_BATCH_NBR NOPARALLEL;


ALTER INDEX PROD.CC_EXT_CLAIM_NUMBER NOPARALLEL;


ALTER INDEX PROD.CC_EXT_EF_CLAIM_NBR NOPARALLEL;


ALTER INDEX PROD.CC_HCC_CLM_NBR NOPARALLEL;


ALTER INDEX PROD.CC_HCC_CLM_NBR_UP NOPARALLEL;


ALTER INDEX PROD.CC_RECEIPT_DATE NOPARALLEL;


ALTER INDEX PROD.CC_STATE_ENDOR_DT NOPARALLEL;


ALTER INDEX PROD.CC_UNRESOLVED_REPROCESS NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_ATTACHMENT_SET NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_AUDIT_LOG NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_CD_ENTRY NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_CLM_BATCH NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_CLM_TOTAL NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_CONSLTD_CLM NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_DENT_CLM_INFO NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_DIAG NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_DIAG_INFO NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_DISCHRG_STATUS NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_EXTERNAL_MBR NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_GEN_VER_REF NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_MBRSHP NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PERSON_NM NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PHONE NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PLACE_OF_SERV NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_POSTAL_ADDR NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PRACT NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PROC_INFO NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_PRVDR_TAXONOMY NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_SPPLR_INV NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_SPPLR_LOC NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_SUBSCRP NOPARALLEL;


ALTER INDEX PROD.FK_CONSLTD_CLM_TYPE_OF_BILL NOPARALLEL;


ALTER INDEX PROD.FK_CONSOLIDATED_CLAIM_DRG NOPARALLEL;


ALTER INDEX PROD.FK_CONSOLIDATED_CLAIM_SUPPLIER NOPARALLEL;


ALTER INDEX PROD.FK_CONS_D_CLM_CD_E_RY_ADMS_RC NOPARALLEL;


ALTER INDEX PROD.FK_CONS_D_CLM_CD_E_RY_CLM_RC NOPARALLEL;


ALTER INDEX PROD.FK_CONS_D_CLM_DR_DRG_OV_RIDE NOPARALLEL;


ALTER INDEX PROD.FK_CONS_D_CLM_POSTAL_DDR_AD NOPARALLEL;


ALTER INDEX PROD.FK_CONS_D_CLM_PRA_ATTND_RACT NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_CD_TRY_ADMS_E_CD NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_CD_TRY_BNFT_P_TYPE NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_CD_TRY_DATE_L_CD NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_DR_CALCULAT_RG_CD NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_POSTA_DR_PAY_T_DR NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_PRA_OPERATI_RACT NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_SPPLR_INV_NTED_NM NOPARALLEL;


ALTER INDEX PROD.FK_CON_CLM_SPPL_NV_CURREN_PUT NOPARALLEL;


ALTER INDEX PROD.FK_CON_D_CLM_CLM_TOTA_OR_PLAN NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_BLUE_CARD_ADER_INFO NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_BLUE_CARD_NG_RESULT NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_CLM_DELEG_TRIBUTES NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_CONS_LM_PREVIO_TATE NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_POST_DR_RESPBL_ADDR NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_PR_OTHR_OP_PRACT NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_SPPL_C_RENDE_LOC NOPARALLEL;


ALTER INDEX PROD.FK_CO_CLM_SPPL_V_PREDET_TION NOPARALLEL;


ALTER INDEX PROD.FK_C_CLM_CD_Y_CALCULAT_N_TYPE NOPARALLEL;


ALTER INDEX PROD.FK_C_CLM_SPPLR_I_ED_NM_SEGM_NM NOPARALLEL;


ALTER INDEX PROD.TENANTID_CONSLTD_CLM NOPARALLEL;

set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off
