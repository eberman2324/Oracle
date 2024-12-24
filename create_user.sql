set echo on verify off term off;

prompt;

create user &1 
identified by "&2" 
default tablespace USERS 
quota unlimited on USERS
temporary tablespace temp
profile STANDARD;

grant APP_USER_ROLE to &1;

alter user &1 default role APP_USER_ROLE;

exit;

