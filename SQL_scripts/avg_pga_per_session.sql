SELECT name, AVG(value)/1024/1024
FROM v$session se, v$sesstat ss, v$statname sn
WHERE ss.sid=se.sid
AND sn.statistic# = ss.statistic#
AND sn.name = 'session pga memory'
AND username = 'PROD'
GROUP BY name
/
