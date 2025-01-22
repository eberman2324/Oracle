


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







create or replace view TEMPtemprpt_free as 
select tablespace_name,sum(bytes) free
from sys.dba_TEMP_Free_space
group by tablespace_name;

create or replace view TEMPtemprpt_bytes as
select tablespace_name,sum(bytes) bytes 
from sys.dba_temp_files
group by tablespace_name;

create or replace view TEMPtemprpt_status as
select a.tablespace_name,free,bytes
from TEMPtemprpt_bytes a,TEMPtemprpt_free b
where a.tablespace_name=b.tablespace_name(+);
