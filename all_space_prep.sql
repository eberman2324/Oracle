Doc
*************************************************************************************
Script:		Space_prep.sql
Title:		Space Report
Author: 	Mark Luddy 	8/1996 - 11/2000
Desc:		This scipts needs to be executed as sys to allow the space 
		report to execute successfully.
*************************************************************************************
#

--
-- create these views as SYS
--

drop view total
/
create view total as
select tablespace_name, file_id, file_name, sum(bytes) bytes,
       sum(blocks) blocks
from dba_data_files
group by tablespace_name, file_id, file_name
/

drop view free
/
create view free as
select tablespace_name, file_id, sum(bytes) bytes,
       sum(blocks) blocks,
sqrt(max(blocks)/sum(blocks)) * (100/(sqrt(sqrt(count(blocks))))) fsfi
from dba_free_space
group by tablespace_name, file_id
/
drop view tab_cnt
/
create view tab_cnt as
select tablespace_name,
        count(table_name) tab_cnt
from dba_tables
group by tablespace_name
/

drop view ind_cnt
/
create view ind_cnt as
select tablespace_name ,
	count(index_name) ind_cnt
from dba_indexes
group by tablespace_name
/

drop view counts
/
create view counts as
select tablespace_name,
       sum(tc) table_count,
       sum(ic) index_count
from
(
select tablespace_name , tab_cnt tc, 0 ic from tab_cnt
union
select tablespace_name, 0, ind_cnt from ind_cnt
union
select tablespace_name, 0, 0 from dba_tablespaces
)
group by tablespace_name
/

drop view ts_total
/
create view ts_total as
select tablespace_name,  sum(bytes) bytes,
       sum(blocks) blocks
from dba_data_files
group by tablespace_name
/

drop view ts_free
/
create view ts_free as
select tablespace_name,  sum(bytes) bytes,
       sum(blocks) blocks,
sqrt(max(blocks)/sum(blocks)) * (100/(sqrt(sqrt(count(blocks))))) fsfi
from dba_free_space
group by tablespace_name
/







create or replace view temprpt_free as 
select tablespace_name,sum(bytes) free
from sys.dba_Free_space
group by tablespace_name;

create or replace view temprpt_bytes as
select tablespace_name,sum(bytes) bytes 
from sys.dba_data_files
group by tablespace_name;

create or replace view temprpt_status as
select a.tablespace_name,free,bytes
from temprpt_bytes a,temprpt_free b
where a.tablespace_name=b.tablespace_name(+);







grant select on sys.counts to dba;
grant select on sys.free to dba;
grant select on sys.total to dba;
grant select on sys.temprpt_status to dba;

