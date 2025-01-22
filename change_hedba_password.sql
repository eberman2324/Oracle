set echo off linesize 120 trimspool on verify on

spool &1._change_hedba_password_&2..out

alter user hedba identified by "OWNEDbyHE#&3.";

spool off;

exit;

