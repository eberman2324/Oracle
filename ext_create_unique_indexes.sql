col DDL for A999 word_wrap
set linesize 1024 pagesize 0 feed off trimspool on verify off
set long 1000000

exec dbms_metadata.set_transform_param(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR', TRUE);

exec dbms_metadata.set_transform_param(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',false);

spool &1._unique_indexes_&2..sql

prompt set sqlblanklines on;;
prompt
prompt alter session force parallel ddl parallel 4;;
prompt

SELECT DBMS_METADATA.GET_DDL('INDEX',index_name,owner) DDL FROM DBA_INDEXES
where index_name like '%AEDBA%'
and (owner,index_name) not in
(select owner,index_name from dba_indexes@ZZ&3 where index_name like '%AEDBA%');
SELECT 'alter index '||owner||'.'||index_name||' noparallel;'
FROM DBA_INDEXES
where index_name like '%AEDBA%'
and (owner,index_name) not in
(select owner,index_name from dba_indexes@ZZ&3 where index_name like '%AEDBA%');

prompt;

