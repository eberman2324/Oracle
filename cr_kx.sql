set pagesize 0
set heading off

spool kx.sql

select 'set echo on' from dual;
select 'spool kx.out' from dual;

select
	'Drop '||substr(object_type,1,30)||' '||owner||'.'||substr(object_name,1,30)||' ; ' 
from
        dba_objects
where
        status <> 'VALID'
	and object_name like 'EUL%';

select 'spool off' from dual;
spool off;
