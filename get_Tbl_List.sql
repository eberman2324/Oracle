set pages 250
SET MARKUP HTML ON SPOOL ON
spool tables.html
SELECT a.object_name,a.created ,b.column_name,b.data_type,b.DATA_LENGTH
FROM dba_objects a,DBA_TAB_COLUMNS b
WHERE
a.owner ='PROD' and a.object_name = b.table_name
AND a.object_type = 'TABLE'
order by a.created desc;
SET MARKUP HTML OFF
spool OFF
