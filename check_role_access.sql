
column	GRANTEE		format a32
column 	OWNER		format a12
column	GRANTOR		format a12
column	PRIVILEGE	format a16
column  last_name	format a14
column	first_name	format a21

set lines 135
set pagesize 20




REM
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column TODAY NEW_VALUE _DATE
column VERSION NEW_VALUES _VERSION
select to_char(SYSDATE,'fmMonth DD, YYYY') TODAY from DUAL;
select version from v$instance;
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.out' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on

spool check_role_access___&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


break on granted_role

PROMPT 	
PROMPT	Roles and who has them...
PROMPT	Granted_role in ('ESCRIPT_MAINTENANCE_ROLE','ADJ_MAINTENANCE_ROLE','ASRX_ORDER_MAINTENANCE_ROLE','ASRX_SYSTEM_TESTING')
PROMPT 	

select
        r.granted_role,
        r.Grantee,
	s.last_name,
	s.first_name,
	r.ADMIN_OPTION,
	r.DEFAULT_ROLE
from
        dba_role_privs r,
        strong_users s
where
        r.grantee=upper(s.username)
--        and r.granted_role in ('ESCRIPT_MAINTENANCE_ROLE','ADJ_MAINTENANCE_ROLE','ASRX_ORDER_MAINTENANCE_ROLE','ASRX_SYSTEM_TESTING')
order by
        r.granted_role,
        r.grantee
;

break on grantee on last_name on first_name



PROMPT 	
PROMPT	USERNAMES and what roles they have...
PROMPT	Granted_role in ('ESCRIPT_MAINTENANCE_ROLE','ADJ_MAINTENANCE_ROLE','ASRX_ORDER_MAINTENANCE_ROLE','ASRX_SYSTEM_TESTING')
PROMPT 	


select
        r.Grantee,
	s.last_name,
	s.first_name,
        r.granted_role,
	r.ADMIN_OPTION,
	r.DEFAULT_ROLE
from
        dba_role_privs r,
        strong_users s
where
        r.grantee=upper(s.username)
 --       and r.granted_role in ('ESCRIPT_MAINTENANCE_ROLE','ADJ_MAINTENANCE_ROLE','ASRX_ORDER_MAINTENANCE_ROLE','ASRX_SYSTEM_TESTING')
order by
	1,4
;






PROMPT 	
PROMPT 	ALL Roles and who has them...
PROMPT 	

select
        r.granted_role,
        r.Grantee,
        s.last_name,
        s.first_name,
	r.ADMIN_OPTION,
	r.DEFAULT_ROLE
from
        dba_role_privs r,
        strong_users s
where
        r.grantee=upper(s.username)
	and s.username in (select username from sys.strong_users)
order by
        r.granted_role,
        r.grantee
;




select t.grantee, t.owner, t.table_name, t.grantor, t.privilege,t.grantable, t.hierarchy, s.last_name, s.first_name
from dba_tab_privs t, strong_users s
where t.grantee=upper(s.username)
order by 1,3; 


select  * from dba_tab_privs where GRANTEE in (select username from sys.strong_users) order by 1,3;


select  * from dba_tab_privs where GRANTEE in (select username from sys.strong_users) order by 1,3;

select  * from dba_tab_privs where GRANTEE IN ('ESCRIPT_MAINTENANCE_ROLE','ASRX_SYSTEM_TESTING') order by 1,3;


spool off;
exit;

