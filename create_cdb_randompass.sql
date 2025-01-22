-- NEWUSER 3.1
-- Last Modified August 27, 2016
--

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_randompass__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

drop function sys.randompass;

CREATE FUNCTION "C##AEDBA"."RANDOMPASS" return varchar2 is
password varchar2(10);
begin

select
dbms_random.string('l',2)||
dbms_random.string('u',2)||
--replace(dbms_random.string('p',1),' ','#')||
decode ((trunc(dbms_random.value (0,9))) ,1,'!',2,'?',3,'#',4,'$',5,'%',6,'?',7,'+',8,'*',9,'(',0,')')||
trunc(dbms_random.value (0,9))||
dbms_random.string('a',2) into password
from
dual;
return password;
end;
/


create public synonym RANDOMPASS for c##aedba.randompass;

spool off;
exit;
