col owner for a20
col table_name for a30
col index_name for a30
set linesize 1024 LONGCHUNKSIZE 20000 pagesize 0 feed off trimspool on
set long 1000000
set serveroutput on size unlimited
--exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'pretty',true);
exec dbms_metadata.set_transform_param(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', TRUE);
spool create_cache_tables.sql  
prompt
prompt "*********************** Extracting Tables DDL ***********************";
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CACHED_CLAIMS','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CACHED_CLAIMS','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CACHED_CLAIMS', 'PROD_DW') FROM DUAL; 
SELECT dbms_metadata.get_ddl('SYNONYM','CACHED_CLAIMS','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CACHED_CLAIMSSUMMARY','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CACHED_CLAIMSSUMMARY','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CACHED_CLAIMSSUMMARY', 'PROD_DW') FROM DUAL; 
SELECT dbms_metadata.get_ddl('SYNONYM','CACHED_CLAIMSSUMMARY','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CACHED_ENROLLMENT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CACHED_ENROLLMENT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CACHED_ENROLLMENT', 'PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_ddl('SYNONYM','CACHED_ENROLLMENT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CACHED_PAYMENTS','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CACHED_PAYMENTS','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CACHED_PAYMENTS', 'PROD_DW') FROM DUAL; 
SELECT dbms_metadata.get_ddl('SYNONYM','CACHED_PAYMENTS','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_CLAIMS_AUDIT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_CLAIMS_AUDIT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_CLAIMS_AUDIT', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_CLAIMS_AUDIT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_CLAIMS_EXT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_CLAIMS_EXT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_CLAIMS_EXT', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_CLAIMS_EXT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_CUR_CLAIMS_EXT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_CUR_CLAIMS_EXT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_CUR_CLAIMS_EXT', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_CUR_CLAIMS_EXT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_MEMBER_FULL','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_MEMBER_FULL','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_MEMBER_FULL', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_MEMBER_FULL','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_PRACTITIONER_EXT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_PRACTITIONER_EXT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_PRACTITIONER_EXT', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_PRACTITIONER_EXT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','CSTMCACHED_SUPPLIER_EXT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','CSTMCACHED_SUPPLIER_EXT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'CSTMCACHED_SUPPLIER_EXT', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','CSTMCACHED_SUPPLIER_EXT','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','DW_DIM_LOGGING','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','DW_DIM_LOGGING','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'DW_DIM_LOGGING', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','DW_DIM_LOGGING','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','TEMP_TRANSACTIONS','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','TEMP_TRANSACTIONS','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'TEMP_TRANSACTIONS', 'PROD_DW') FROM DUAL; 
--SELECT dbms_metadata.get_ddl('SYNONYM','TEMP_TRANSACTIONS','PUBLIC') from dual;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','TABLES_THAT_CAN_BE_TRUNCATED','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','TABLES_THAT_CAN_BE_TRUNCATED','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'TABLES_THAT_CAN_BE_TRUNCATED', 'PROD_DW') FROM DUAL;
prompt
SELECT DBMS_METADATA.GET_DDL('TABLE','AUDIT_LOG_ARCHIVE_FACT','PROD_DW') FROM DUAL;
SELECT dbms_metadata.get_dependent_ddl('INDEX','AUDIT_LOG_ARCHIVE_FACT','PROD_DW') from dual;
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'AUDIT_LOG_ARCHIVE_FACT', 'PROD_DW') FROM DUAL;
prompt
SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', 'AUDIT_LOG_ENTRY_FACT', 'PROD_DW') FROM DUAL;

spool off

