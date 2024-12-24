set trimspool on feed off pagesize 0 term off

spool &1._user_names_&2..out

SELECT USERNAME
FROM DBA_USERS
WHERE ORACLE_MAINTAINED = 'N'
AND USERNAME NOT IN ('AEAUDIT','DBCMS','OJVMSYS','TOM')
ORDER BY USERNAME;

spool off

