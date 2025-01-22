set echo on

spool create_comet_user_${ORACLE_SID}.out2

drop user s041969; 

create user S044974
identified by "&1"
default tablespace users
quota unlimited on users
temporary tablespace temp2;

grant create session to S044974;

grant comet_gateway to S044974;

SPOOL OFF;
EXIT;

--
--
