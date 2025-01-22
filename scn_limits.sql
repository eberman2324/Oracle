set linesize 360
WITH limits AS (
  SELECT 
      current_scn
  --, dbms_flashback.get_system_change_number as current_scn -- Oracle 9i
    , (SYSDATE - TO_DATE('1988-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) * 24*60*60 * 16384 
        AS SCN_soft_limit
    , 281474976710656 AS SCN_hard_limit
  FROM V$DATABASE
)
SELECT
    current_scn
  , current_scn/scn_soft_limit*100 AS pct_soft_limit_exhausted
  , scn_soft_limit
  , current_scn/scn_hard_limit*100 AS pct_hard_limit_exhausted
  , scn_hard_limit
FROM limits;
