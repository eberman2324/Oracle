-- This shoulbe run on DBATST database ------------
select sample_date,sum(used_space) from aedba.ae_spaceinfo where db_name = 'wkabprod' 
and space_type = 'TABLESPACE' and space_name not in ('TEMP','UNDOTBS') group by sample_date order by sample_date

--WKABPROD
select to_char(sample_date, 'YYYY-MM-DD HH24:MI') as sample_date, 
sum(used_space) as used_mbytes ,
sum(used_space) - lag(sum(used_space), 1) over (order by to_char(sample_date, 'YYYY-MM-DD HH24:MI')) as DIFF
from aedba.ae_spaceinfo 
where db_name='wkabprod' 
and space_type='TABLESPACE' 
and space_name not in ('TEMP', 'UNDOTBS') 
and sample_date >= to_date('03/31/2013', 'MM/DD/YYYY') 
group by to_char(sample_date, 'YYYY-MM-DD HH24:MI') 
order by 1

--DR02
select to_char(sample_date, 'YYYY-MM-DD HH24:MI') as sample_date, 
sum(used_space) as used_mbytes ,
sum(used_space) - lag(sum(used_space), 1) over (order by to_char(sample_date, 'YYYY-MM-DD HH24:MI')) as DIFF
from aedba.ae_spaceinfo 
where db_name='DR02' 
and space_type='TABLESPACE' 
and space_name not in ('TEMP', 'UNDOTBS') 
and sample_date >= to_date('06/30/2009', 'MM/DD/YYYY') 
group by to_char(sample_date, 'YYYY-MM-DD HH24:MI') 
order by 1

--DM02
select to_char(sample_date, 'YYYY-MM-DD HH24:MI') as sample_date, 
sum(used_space) as used_mbytes ,
sum(used_space) - lag(sum(used_space), 1) over (order by to_char(sample_date, 'YYYY-MM-DD HH24:MI')) as DIFF
from aedba.ae_spaceinfo 
where db_name='DM02' 
and space_type='TABLESPACE' 
and space_name not in ('TEMP', 'UNDOTBS') 
and sample_date >= to_date('12/31/2008', 'MM/DD/YYYY') 
group by to_char(sample_date, 'YYYY-MM-DD HH24:MI') 
order by 1



select * from aedba.ae_spaceinfo

