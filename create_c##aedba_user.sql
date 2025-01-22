
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_c##aedba_account__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


CREATE USER "C##AEDBA" PROFILE "DEFAULT" IDENTIFIED BY "#NotBitt3r" DEFAULT TABLESPACE audit_space TEMPORARY TABLESPACE "TEMP" ACCOUNT UNLOCK
/
GRANT UNLIMITED TABLESPACE TO "C##AEDBA"
/
GRANT connect TO "C##AEDBA"
/
GRANT resource TO "C##AEDBA"
/
alter user C##AEDBA default role all
/
