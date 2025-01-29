set trimspool on

spool drop_sysman_etc.out

SHUTDOWN IMMEDIATE;

STARTUP RESTRICT;

EXEC sysman.emd_maintenance.remove_em_dbms_jobs;

EXEC sysman.setEMUserContext('',5);

REVOKE dba FROM sysman;

DECLARE
CURSOR c1 IS
SELECT owner, synonym_name name
FROM dba_synonyms
WHERE table_owner = 'SYSMAN'
;
BEGIN
FOR r1 IN c1 LOOP
IF r1.owner = 'PUBLIC' THEN
EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM '||r1.name;
ELSE 
EXECUTE IMMEDIATE 'DROP SYNONYM '||r1.owner||'.'||r1.name;
END IF;
END LOOP;
END;
/
DROP USER mgmt_view CASCADE;

DROP ROLE mgmt_user;

DROP USER sysman CASCADE;

ALTER SYSTEM DISABLE RESTRICTED SESSION;

spool off

