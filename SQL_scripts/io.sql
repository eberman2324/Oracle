col event for a25
select event,round(min(p3)) mn,
round(avg(p3)) av,
round(max(p3)) mx,
count(*)  cnt
from dba_hist_active_sess_history
--from v$active_session_history
where  (event like 'db file%' or event like 'direct %')
and event not like '%parallel%'
group by event
order by event
/

