set lines 150

col type for a24
col "CPU" for 999999.9
col "IO" for 999999.9

select * from (
select
     ash.SQL_ID , ash.SQL_PLAN_HASH_VALUE Plan_hash, aud.name type,
     sum(decode(ash.session_state,'ON CPU',1,0))     "CPU",
     sum(decode(ash.session_state,'WAITING',1,0))    -
     sum(decode(ash.session_state,'WAITING', decode(wait_class, 'User I/O',1,0),0))    "WAIT" ,
     sum(decode(ash.session_state,'WAITING', decode(wait_class, 'User I/O',1,0),0))    "IO" ,
     sum(decode(ash.session_state,'ON CPU',1,1))     "TOTAL"
from dba_hist_active_sess_history ash,
     audit_actions aud
where SQL_ID is not NULL
   and ash.sql_opcode=aud.action
   -- and ash.sample_time > sysdate - &minutes /( 60*24)
group by sql_id, SQL_PLAN_HASH_VALUE   , aud.name 
order by sum(decode(session_state,'ON CPU',1,1))   desc
) where  rownum < 10
/



