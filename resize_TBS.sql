col type for a5
col ts for a5

spool resize_TBS.out

select name as DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from v$database;

set feed on

set echo on timing on head off

ALTER DATABASE DATAFILE '+DATA_01/HEPYPRD_XHEPYDBM1P/DATAFILE/data5.689.1113717387' RESIZE 1500G;



set feed off

select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;

spool off