SELECT a.* FROM DBA_HIST_SQLTEXT b, table
(DBMS_XPLAN.DISPLAY_AWR(b.sql_id,null, null, 'ALL' )) a
WHERE b.sql_text like '%SELECT%';