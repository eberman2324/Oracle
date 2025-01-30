CREATE TABLE AEDBA.AD_CONFIG
(
    CONFIG_VAR  VARCHAR2(50)  NOT NULL,
    CONFIG_VAL  VARCHAR2(500)     NULL,
    NOTES       VARCHAR2(500)     NULL,
    INACTIVE_DT DATE              NULL,
    CONFIG_VAL2 VARCHAR2(500)     NULL
)
ORGANIZATION HEAP
TABLESPACE DATA5
LOGGING
PCTFREE 10
PCTUSED 0
INITRANS 1
MAXTRANS 255
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
NOROWDEPENDENCIES
NO INMEMORY
/
CREATE UNIQUE INDEX AEDBA.AD_CONFIG
    ON AEDBA.AD_CONFIG(CONFIG_VAR)
TABLESPACE INDX5
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
NOPARALLEL
NOCOMPRESS
/
GRANT INSERT ON AEDBA.AD_CONFIG TO A229515
/
GRANT SELECT ON AEDBA.AD_CONFIG TO A229515
/
GRANT UPDATE ON AEDBA.AD_CONFIG TO A229515
/
GRANT INSERT ON AEDBA.AD_CONFIG TO A603481
/
GRANT SELECT ON AEDBA.AD_CONFIG TO A603481
/
GRANT UPDATE ON AEDBA.AD_CONFIG TO A603481
/
ALTER TABLE AEDBA.AD_CONFIG
    ADD CONSTRAINT CONFIG_ICR
    PRIMARY KEY (CONFIG_VAR)
    USING INDEX AEDBA.AD_CONFIG
/
