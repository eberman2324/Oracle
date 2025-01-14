set verify off
set feedback off
set echo off
set trimspool on
set trimout on
set linesize 150
set pagesize 999

col TSPACE_NAME         for     a15
col TOTAL_SPACE         for     999,999,999,999
col MAX_FREE_SPACE      for     999,999,999,999
col COUNT_FREE_BLOCKS   for     999,999,999
col TOTAL_FREE_SPACE    for     999,999,999,999
col USED_SPACE          for     999,999,999,999
col PERCENT_FREE        for     999

spool &1 APPEND

select name as "DataBase", to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "CurrDate" from v$database;

prompt
select TSPACE_NAME,
       TOTAL_SPACE,
       MAX_FREE_SPACE,
       COUNT_FREE_BLOCKS,
       TOTAL_FREE_SPACE,
       TOTAL_SPACE-TOTAL_FREE_SPACE AS USED_SPACE,
       100*TOTAL_FREE_SPACE/TOTAL_SPACE AS PERCENT_FREE
  from
      (select Tablespace_Name TSPACE_NAME,
              SUM(Bytes)/1024 TOTAL_SPACE
         from DBA_DATA_FILES
        group by Tablespace_Name),
      (select Tablespace_Name FS_TS_NAME,
              MAX(Bytes)/1024  AS MAX_FREE_SPACE,
              SUM(Blocks)  AS COUNT_FREE_BLOCKS,
              SUM(Bytes)/1024 AS TOTAL_FREE_SPACE
         from DBA_FREE_SPACE
        group by Tablespace_Name)
 where TSPACE_NAME = FS_TS_NAME
order by TSPACE_NAME;

set pagesize 0

select substr(rpad(dummy,123,'-'),2) from dual;
select substr(rpad(dummy,123,'-'),2) from dual;

spool off

