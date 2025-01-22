spool go_compile_invalids.info 

select object_type, 
	substr(owner,1,8) "Owner",
	substr(object_name,1,30) "Object",
	status,
	object_type "Type"
from dba_objects 
where status = 'INVALID'
order by object_type
;

spool off;

set pagesize 0
set heading off

spool go_compile_invalids.sql 

select 'set echo on ' from dual;
-- select 'time on timing on' from dual;
select 'spool go_compile_invalids.out;' from dual;

select
	'alter ' ||
	decode(object_type,'PACKAGE BODY','PACKAGE',object_type)||
	'  '||
	owner||
	'.'||
	substr(object_name,1,30)||
	' compile '||
	decode(object_type,'PACKAGE BODY','BODY ',' ')||' ;'
	||chr(13)||chr(10)||	'show errors;'
	||chr(13)||chr(10)|| '-- ----------------------------------------------------------------- '
	||chr(13)||chr(10)|| '-- ----------------------------------------------------------------- '
	||chr(13)||chr(10)|| '-- ----------------------------------------------------------------- '
	||chr(13)||chr(10)||chr(13)||chr(10)
from dba_objects 
where status = 'INVALID'
order by object_type
;

select 'spool off;' from dual;

spool off;

set pagesize 14
set heading on

