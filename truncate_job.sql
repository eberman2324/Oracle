set echo on

spool truncate_job__${ORACLE_SID}.out

select count(*) from   PROD.BLOB_MEMBERSHIP  ;
select count(*) from   PROD.BLOB_MEMBER_SELECTIONS  ;
select count(*) from   PROD.BLOB_PRACTITIONER  ;
select count(*) from   PROD.BLOB_PRACTITIONER_ROLE  ;
select count(*) from   PROD.BLOB_SUBSCRIPTION  ;
select count(*) from   PROD.BLOB_SUBSCRIPTION_SELECTIONS  ;
select count(*) from   PROD.BLOB_SUPPLIER  ;
select count(*) from   PROD.BLOB_SUPPLIER_LOCATION  ;
select count(*) from   PROD.BLOB_TAX_ENTITY  ;
select count(*) from   PROD.BLOB_MEDICARE_HICN_INFO  ;

Truncate table  PROD.BLOB_MEMBERSHIP  ;
Truncate table  PROD.BLOB_MEMBER_SELECTIONS  ;
Truncate table  PROD.BLOB_PRACTITIONER  ;
Truncate table  PROD.BLOB_PRACTITIONER_ROLE  ;
Truncate table  PROD.BLOB_SUBSCRIPTION  ;
Truncate table  PROD.BLOB_SUBSCRIPTION_SELECTIONS  ;
Truncate table  PROD.BLOB_SUPPLIER  ;
Truncate table  PROD.BLOB_SUPPLIER_LOCATION  ;
Truncate table  PROD.BLOB_TAX_ENTITY  ;
Truncate table  PROD.BLOB_MEDICARE_HICN_INFO  ;


spool off;
exit;
