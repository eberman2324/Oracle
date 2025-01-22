col type for a5
col ts for a5

spool add_indexes_CAPITATED_PAYMENT_LINE.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on



set echo on timing on head off

CREATE INDEX PROD.FK_CAPITATED_PAYMENT_LINE_ZIP
    ON PROD.CAPITATED_PAYMENT_LINE(ZIP_CD)
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
CREATE INDEX PROD.FK_CAPITATED_PAYMNT_LN_COUNTY
    ON PROD.CAPITATED_PAYMENT_LINE(COUNTY_ID)
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
CREATE INDEX PROD.FK_CAPITATED_PAYMNT_LN_MBRSHP
    ON PROD.CAPITATED_PAYMENT_LINE(MBRSHP_ID)
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
CREATE INDEX PROD.FK_CAPITATED_PAYMNT_LN_SUBSCRP
    ON PROD.CAPITATED_PAYMENT_LINE(SUBSCRP_ID)
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
CREATE INDEX PROD.FK_CAPITATE_PAYMNT_LN_CD_E_RY
    ON PROD.CAPITATED_PAYMENT_LINE(CD_ENTRY_ID)
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
CREATE INDEX PROD.FK_CAPITATE_PAYMNT_LN_COV_IER
    ON PROD.CAPITATED_PAYMENT_LINE(COV_TIER_ID)
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
CREATE INDEX PROD.FK_CAPITAT_AYMNT_LN_MBR_P_MB
    ON PROD.CAPITATED_PAYMENT_LINE(MBR_MBRSHP_ID)
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
CREATE INDEX PROD.FK_CAPITAT_AYMNT_LN_ZI_MBR_IP
    ON PROD.CAPITATED_PAYMENT_LINE(MBR_ZIP_ZIP_CD)
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
CREATE INDEX PROD.FK_CAPITAT_PAYMNT_LN_BNFT_LAN
    ON PROD.CAPITATED_PAYMENT_LINE(BNFT_PLAN_ID)
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
CREATE INDEX PROD.FK_CAPITAT_PAYMNT_LN_SPPLR_OC
    ON PROD.CAPITATED_PAYMENT_LINE(SPPLR_LOC_ID)
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
CREATE INDEX PROD.FK_CAPITA_AYMNT_LN_COV_T_SET
    ON PROD.CAPITATED_PAYMENT_LINE(COV_TIER_SET_ID)
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
CREATE INDEX PROD.FK_CAPITA_AYMNT_LN_SPPLR_TWRK
    ON PROD.CAPITATED_PAYMENT_LINE(SPPLR_NETWRK_ID)
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
CREATE INDEX PROD.FK_CAPIT_MNT_LN_CD_RY_PANE_PE
    ON PROD.CAPITATED_PAYMENT_LINE(PANEL_TYPE_CD_ENTRY_ID)
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
CREATE INDEX PROD.FK_CAPIT_MNT_LN_CD_RY_ROST_PE
    ON PROD.CAPITATED_PAYMENT_LINE(ROSTER_TYPE_CD_ENTRY_ID)
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
CREATE INDEX PROD.FK_CAPIT_MNT_LN_CO_Y_PRVD_NTY
    ON PROD.CAPITATED_PAYMENT_LINE(PRVDR_COUNTY_COUNTY_ID)
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
CREATE INDEX PROD.FK_CAPIT_YMNT_LN_CD_RY_SPEC_V
    ON PROD.CAPITATED_PAYMENT_LINE(SPEC_SERV_CD_ENTRY_ID)
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
CREATE INDEX PROD.FK_CAPIT_YMNT_LN_CO_Y_MBR_NTY
    ON PROD.CAPITATED_PAYMENT_LINE(MBR_COUNTY_COUNTY_ID)
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
CREATE INDEX PROD.FK_CAPI_MNT_LN_CD_RY_MBR_H_ND
    ON PROD.CAPITATED_PAYMENT_LINE(MBR_HLTH_COND_CD_ENTRY_ID)
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
CREATE INDEX PROD.FK_CAPI_MNT_LN_SPPL_RK_SPEC_RK
    ON PROD.CAPITATED_PAYMENT_LINE(SPEC_NETWRK_SPPLR_NETWRK_ID)
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
CREATE INDEX PROD.FK_CAP_NT_LN_CAPITATE_DETAIL
    ON PROD.CAPITATED_PAYMENT_LINE(CAPITATED_PAYA_VABLE_DETAIL_ID)
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
CREATE INDEX PROD.TENANTID_CAPITATED_PAYMNT_LN
    ON PROD.CAPITATED_PAYMENT_LINE(TENANT_ID)
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




ALTER INDEX PROD.FK_CAPITATED_PAYMENT_LINE_ZIP NOPARALLEL;


ALTER INDEX PROD.FK_CAPITATED_PAYMNT_LN_COUNTY NOPARALLEL;


ALTER INDEX PROD.FK_CAPITATED_PAYMNT_LN_MBRSHP NOPARALLEL;

ALTER INDEX PROD.FK_CAPITATED_PAYMNT_LN_SUBSCRP NOPARALLEL;

ALTER INDEX PROD.FK_CAPITATE_PAYMNT_LN_CD_E_RY NOPARALLEL;

ALTER INDEX PROD.FK_CAPITATE_PAYMNT_LN_COV_IER NOPARALLEL;

ALTER INDEX PROD.FK_CAPITAT_AYMNT_LN_MBR_P_MB NOPARALLEL;

ALTER INDEX PROD.FK_CAPITAT_AYMNT_LN_ZI_MBR_IP NOPARALLEL;

ALTER INDEX PROD.FK_CAPITAT_PAYMNT_LN_BNFT_LAN NOPARALLEL;

ALTER INDEX PROD.FK_CAPITAT_PAYMNT_LN_SPPLR_OC NOPARALLEL;

ALTER INDEX PROD.FK_CAPITA_AYMNT_LN_COV_T_SET NOPARALLEL;

ALTER INDEX PROD.FK_CAPITA_AYMNT_LN_SPPLR_TWRK NOPARALLEL;

ALTER INDEX PROD.FK_CAPIT_MNT_LN_CD_RY_PANE_PE NOPARALLEL;

ALTER INDEX PROD.FK_CAPIT_MNT_LN_CD_RY_ROST_PE NOPARALLEL;

ALTER INDEX PROD.FK_CAPIT_MNT_LN_CO_Y_PRVD_NTY NOPARALLEL;

ALTER INDEX PROD.FK_CAPIT_YMNT_LN_CD_RY_SPEC_V NOPARALLEL;

ALTER INDEX PROD.FK_CAPIT_YMNT_LN_CO_Y_MBR_NTY NOPARALLEL;

ALTER INDEX PROD.FK_CAPI_MNT_LN_CD_RY_MBR_H_ND NOPARALLEL;

ALTER INDEX PROD.FK_CAPI_MNT_LN_SPPL_RK_SPEC_RK NOPARALLEL;

ALTER INDEX PROD.FK_CAP_NT_LN_CAPITATE_DETAIL NOPARALLEL;

ALTER INDEX PROD.TENANTID_CAPITATED_PAYMNT_LN NOPARALLEL;

set echo off timing off head on feed on


set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off

