set heading off;
set feedback off;
set pagesize 0;

spool kx_ts_file_${ORACLE_SID}.sh;

select '#!/bin/ksh' from dual ;

select 'echodo rm '||file_name
from dba_data_files
order by tablespace_name ;

select 'echodo rm '||file_name
from dba_temp_files
order by tablespace_name ;

select 'echodo rm '||substr(member,1,50) from v$logfile ;
select 'echodo rm '||name from v$controlfile ;

spool off;

select ' ' from dual;
select '-- REMEMBER TO CHMOD TO MAKE EXECUTIBLE' from dual;
select ' ' from dual;

set heading on;
set feedback on;

exit;

