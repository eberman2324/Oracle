
select
    trunc(first_time) day,  
    substr(to_char(first_time, 'hh24:mi'), 1, 4) || '0' as time,  
    count(*) switches  
  from  
   v$log_history  
 where 
   trunc(first_time) between 
       trunc(to_date('20.01.2017', 'dd.mm.yyyy')) 
   and 
       trunc(to_date('24.01.2017', 'dd.mm.yyyy'))  
 group by 
   trunc(first_time), 
   substr(to_char(first_time, 'hh24:mi'), 1, 4)  
having 
   count(*) > 1  
 order by 1, 2; 
