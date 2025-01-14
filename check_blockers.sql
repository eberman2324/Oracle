set feed off
set pagesize 200
set lines 299
col event for a31
Column          SQL_ID format a30
--Column          BLOCKING_SESSION format a5
SELECT
s.sql_id as SQL_ID,
s.blocking_session as BLOCKING_SESSION
FROM
gv$session s
WHERE
blocking_session IS NOT NULL and s.seconds_in_wait > 10;
