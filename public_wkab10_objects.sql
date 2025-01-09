select DISTINCT TABLE_NAME from dba_tab_privs where owner = 'WKAB10' and GRANTEE = 'PUBLIC'
and PRIVILEGE IN ('SELECT','INSERT','UPDATE','DELETE','ALTER','EXECUTE')
