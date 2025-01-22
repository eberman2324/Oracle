Def v_secs=3600 --  bucket size
Def v_days=1 --  total time analyze
Def v_bars=5 -- size of one AAS in characters
Def v_graph=80 

col aveact format 999.99
col graph format a80
col fpct format 9.99
col spct format 9.99
col tpct format 9.99
col aas format 999.99
col aas1 format 9.99
col aas2 format 9.99
col pct1 format 999
col pct2 format 999
col first format  a15
col second format  a15

Def p_value=4

select to_char(start_time,'DD HH24:MI'),
       --samples,
       --total,
       --waits,
       --cpu,
       (total/&v_secs) aas,
       --round(fpct * (total/&v_secs),2) aas1,
       fpct*100  pct1,
       decode(fpct,null,null,first) first,
       --round(spct * (total/&v_secs),2) aas2,
       spct*100 pct2,
       decode(spct,null,null,second) second,
    -- substr, ie trunc, the whole graph to make sure it doesn't overflow
        substr(
       -- substr, ie trunc, the graph below the # of CPU cores line
           -- draw the whole graph and trunc at # of cores line
       substr(
         rpad('+',round((cpu*&v_bars)/&v_secs),'+') ||
             rpad('o',round((io*&v_bars)/&v_secs),'o')  ||
             rpad('-',round((waits*&v_bars)/&v_secs),'-')  ||
             rpad(' ',&p_value * &v_bars,' '),0,(&p_value * &v_bars)) ||
        &p_value  ||
       -- draw the whole graph, then cut off the amount we drew before the # of cores
           substr(
         rpad('+',round((cpu*&v_bars)/&v_secs),'+') ||
             rpad('o',round((io*&v_bars)/&v_secs),'o')  ||
             rpad('-',round((waits*&v_bars)/&v_secs),'-')  ||
             rpad(' ',&p_value * &v_bars,' '),(&p_value * &v_bars),( &v_graph-&v_bars*&p_value) )
        ,0,&v_graph)
        graph
     --  spct,
     --  decode(spct,null,null,second) second,
     --  tpct,
     --  decode(tpct,null,null,third) third
from (
select start_time
     , max(samples) samples
     , sum(top.total) total
     , round(max(decode(top.seq,1,pct,null)),2) fpct 
     , substr(max(decode(top.seq,1,decode(top.event,'ON CPU','CPU',event),null)),0,15) first
     , round(max(decode(top.seq,2,pct,null)),2) spct
     , substr(max(decode(top.seq,2,decode(top.event,'ON CPU','CPU',event),null)),0,15) second
     , round(max(decode(top.seq,3,pct,null)),2) tpct
     , substr(max(decode(top.seq,3,decode(top.event,'ON CPU','CPU',event),null)),0,10) third
     , sum(waits) waits
     , sum(io) io
     , sum(cpu) cpu
from (
  select
       to_date(tday||' '||tmod*&v_secs,'YYMMDD SSSSS') start_time
     , event
     , total
     , row_number() over ( partition by id order by total desc ) seq
     , ratio_to_report( sum(total)) over ( partition by id ) pct
     , max(samples) samples
     , sum(decode(event,'ON CPU',total,0))    cpu
     , sum(decode(event,'ON CPU',0,
                        'db file sequential read',0,
                        'db file scattered read',0,
                        'db file parallel read',0,
                        'direct path read',0,
                        'direct path read temp',0,
                        'direct path write',0,
                        'direct path write temp',0, total)) waits
     , sum(decode(event,'db file sequential read',total,
                                  'db file scattered read',total,
                                  'db file parallel read',total,
                                  'direct path read',total,
                                  'direct path read temp',total,
                                  'direct path write',total,
                                  'direct path write temp',total, 0)) io
  from (
    select
         to_char(sample_time,'YYMMDD')                      tday
       , trunc(to_char(sample_time,'SSSSS')/&v_secs)          tmod
       , to_char(sample_time,'YYMMDD')||trunc(to_char(sample_time,'SSSSS')/&v_secs) id
       , decode(ash.session_state,'ON CPU','ON CPU',ash.event)     event
       , sum(decode(session_state,'ON CPU',10,decode(session_type,'BACKGROUND',0,10))) total
       , (max(sample_id)-min(sample_id)+1)                    samples
     from
        dba_hist_active_sess_history ash
     where
        --       sample_time > sysdate - &v_days
        -- and sample_time < ( select min(sample_time) from v$active_session_history)
           dbid=&DBID
      and  sql_id='&SQL_ID'
     group by  trunc(to_char(sample_time,'SSSSS')/&v_secs)
            ,  to_char(sample_time,'YYMMDD')
            ,  decode(ash.session_state,'ON CPU','ON CPU',ash.event)
  )  chunks
  group by id, tday, tmod, event, total
) top
group by start_time
) aveact
order by start_time
/



