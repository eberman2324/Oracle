
with t as
  ( select TO_CHAR(dbms_metadata.get_ddl('USER','S057147')) ddl from dual )
  select replace(substr(ddl,1,instr(ddl,'DEFAULT')-1),'CREATE','ALTER')||';'
  from t;
