Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_aeaudit_account__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

CREATE USER AEAUDIT IDENTIFIED BY VALUES 'D3CF3912523E800E' 
    DEFAULT TABLESPACE USERS 
    TEMPORARY TABLESPACE TEMP 
    PROFILE TRUSTED_ID_NO_EXPIRE
    ACCOUNT UNLOCK 
/ 
GRANT "CONNECT" TO AEAUDIT 
/ 
ALTER USER AEAUDIT DEFAULT ROLE "CONNECT" 
/ 
GRANT SELECT ON SYS.OBJ$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.V_$DATABASE TO AEAUDIT 
/ 
GRANT SELECT ON SYS.USER$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.OBJAUTH$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.SYSAUTH$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.DEFROLE$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.PROFILE$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.PROFNAME$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.SYSTEM_PRIVILEGE_MAP TO AEAUDIT 
/ 
GRANT SELECT ON SYS.TABLE_PRIVILEGE_MAP TO AEAUDIT 
/ 
GRANT SELECT ON SYS.RESOURCE_MAP TO AEAUDIT 
/ 
GRANT SELECT ON SYS.USER_ASTATUS_MAP TO AEAUDIT 
/ 
GRANT SELECT ON SYS.AUD$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.RESOURCE_GROUP_MAPPING$ TO AEAUDIT 
/ 
GRANT SELECT ON SYS.TS$ TO AEAUDIT 
/ 
GRANT SELECT ANY DICTIONARY TO AEAUDIT 
/ 
