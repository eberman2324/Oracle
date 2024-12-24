set echo off linesize 120 trimspool on

spool &1._create_OPTIM_user.out

CREATE USER S022498 IDENTIFIED BY VALUES 'S:3E4CDF3AEBD414EA353F6F9E21AB2CE6345F3BD1AC8EB4392CBE12399C81;H:213399B3E2189D068D730B7086769F96;T:64CF0AE4AE0098B1A766F37E5FC98F1213BE42129D12BA0BFCEE318014E5234566BE724E3A5836AB3AE84B9448B87704BEEF9A615550E583E5B490FD1B990B2758233F34F4D8692E09391BE8A5E7296F;DAF5C4560146AB5A'
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS
    PROFILE TRUSTED_ID_NO_EXPIRE
    ACCOUNT UNLOCK
/

GRANT READ_ONLY TO S022498
/
ALTER USER S022498 DEFAULT ROLE READ_ONLY
/

spool off;

exit