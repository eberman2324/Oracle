
set echo on trimspool on

spool lock_user_accounts.out

alter user A142052 account lock;
alter user A170895 account lock;
alter user A229515 account lock;
alter user A528733 account lock;
alter user A568125 account lock;
alter user A604222 account lock;
alter user A707000 account lock;
alter user N025774 account lock;
alter user N078218 account lock;
alter user N099358 account lock;
alter user N107748 account lock;
alter user N108478 account lock;
alter user N217924 account lock;
alter user N230034 account lock;
alter user N231156 account lock;
alter user N244116 account lock;
alter user N628377 account lock;
alter user N713029 account lock;
alter user N718049 account lock;
alter user N718052 account lock;
alter user N749911 account lock;
alter user N750108 account lock;
alter user N750400 account lock;
alter user N750402 account lock;
alter user N751824 account lock;
alter user N758767 account lock;
alter user N773528 account lock;

spool off

!chmod 600 lock_user_accounts.out

exit

