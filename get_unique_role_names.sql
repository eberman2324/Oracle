set trimspool on feed off pagesize 0 term off verify off

spool &1._unique_role_names_&2..out

SELECT ROLE
FROM DBA_ROLES
WHERE ORACLE_MAINTAINED = 'N'
AND ROLE NOT IN
(SELECT ROLE FROM DBA_ROLES@ZZ&3)
ORDER BY ROLE;

spool off

