spool create_indexes_${ORACLE_SID}.out

CREATE INDEX PROD.hcfa1500_AEDBA_1
    ON PROD.hcfa1500("SPPLR_INFO_TAX_IDENT_NBR")
TABLESPACE INDX ONLINE PARALLEL 3;

ALTER INDEX  prod.hcfa1500_AEDBA_1 NOPARALLEL;

CREATE INDEX PROD.postal_address_AEDBA_3
    ON PROD.postal_address("ADDRESS3_TXT")
TABLESPACE INDX ONLINE PARALLEL 3;

ALTER INDEX  PROD.postal_address_AEDBA_3 NOPARALLEL;

CREATE INDEX PROD.MED_HICN_INFO_AEDBA_1
    ON PROD.MEDICARE_HICN_INFO("HICN_TXT")
TABLESPACE INDX ONLINE PARALLEL 4;

ALTER INDEX  PROD.MED_HICN_INFO_AEDBA_1 NOPARALLEL;

CREATE INDEX PROD.CC_AEDBA_1
    ON PROD.CONSOLIDATED_CLAIM("SUBMITTE_INFO_SPPLR_NUM_TXT")
TABLESPACE INDX ONLINE PARALLEL 4;

ALTER INDEX  PROD.CC_AEDBA_1 NOPARALLEL;


CREATE INDEX PROD.CC_AEDBA_2
    ON PROD.CONSOLIDATED_CLAIM("SUBMITT_R_INFO_SPPLR_NUM_TXT")
TABLESPACE INDX ONLINE PARALLEL 4;

ALTER INDEX  PROD.CC_AEDBA_2 NOPARALLEL;

spool off
