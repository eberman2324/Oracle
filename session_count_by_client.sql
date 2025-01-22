
col machine form a32
set linesize 360
SELECT machine,
       NVL(active_count, 0) AS active,
       NVL(inactive_count, 0) AS inactive,
       NVL(killed_count, 0) AS killed 
FROM   (SELECT machine, status, count(*) AS quantity
        FROM   v$session
        GROUP BY machine, status)
PIVOT  (SUM(quantity) AS count FOR (status) IN ('ACTIVE' AS active, 'INACTIVE' AS inactive, 'KILLED' AS killed))
ORDER BY machine;
