set trimspool on feed off pagesize 0 term off verify off

spool &1._role_names_&2..out

SELECT ROLE
FROM DBA_ROLES
WHERE ORACLE_MAINTAINED = 'N'
ORDER BY ROLE;

spool off

