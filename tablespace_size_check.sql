SELECT CAST(b.tablespace_name || DECODE(SUM(DECODE(b.autoextensible, 'YES', 1, 
0)), 0, '', '*')AS VARCHAR2(31)) AS tablespace_name,
   SUM(b.bytes) / 1024 / 1024 AS Size_MBytes,
   NVL(SUM(a.bytes), 0) / 1024 / 1024 AS Free_MBytes,
   (SUM(b.bytes) - NVL(SUM(a.bytes), 0)) / 1024 / 1024 AS Used_MBytes,
   (SUM(b.bytes) - SUM(b.user_bytes)) / 1024 / 1024 AS Bitmap_MBytes,
   100.0 - 100.0 * NVL(SUM(a.bytes), 0) / SUM(b.bytes) AS PCT_Used
FROM dba_data_files b, (
   SELECT file_id,
      SUM(bytes) AS bytes
   FROM dba_free_space 
   GROUP BY file_id) a 
WHERE a.file_id (+) = b.file_id 
GROUP BY b.tablespace_name UNION ALL 
SELECT CAST(b.tablespace_name || DECODE(SUM(DECODE(b.autoextensible, 'YES', 1, 
0)), 0, '', '*') AS VARCHAR2(31)) AS tablespace_name,
   SUM(b.bytes) / 1024 / 1024 AS Size_MBytes,
   SUM(a.bytes_free) / 1024 / 1024 AS Free_MBytes,
   SUM(a.bytes_used) / 1024 / 1024 AS Used_MBytes,
   (SUM(b.bytes) - SUM(b.user_bytes)) / 1024 / 1024 AS Bitmap_MBytes,
   100.0 * SUM(a.bytes_used) / SUM(b.bytes) AS PCT_Used
FROM dba_temp_files b, (
   SELECT file_id,
      SUM(bytes_used) AS bytes_used,
      SUM(bytes_free) AS bytes_free
   FROM V$TEMP_SPACE_HEADER 
   GROUP BY file_id) a 
WHERE a.file_id (+) = b.file_id 
GROUP BY b.tablespace_name 
ORDER BY 6