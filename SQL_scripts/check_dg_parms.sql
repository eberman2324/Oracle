Doc
*************************************************************************************
Script:         check_dg_parms.sql
Title:          Check Data Guard Parameters
Author:         Mark Luddy      2005
Desc:           This script shows Data Guard information
*************************************************************************************
#

set lines 140
set pagesize 25

column 	dest_name	format a20
column  name            format a30
column  value           format a100


Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool check_dg_parms__&&dbname&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


select name, value
from v$parameter
where name in (
                'db_name', 'db_unique_name', 'log_archive_config',
                'log_archive_dest_1','log_archive_dest_2', 'log_archive_dest_3','log_archive_dest_state_1',
                'log_archive_dest_state_2', 'log_archive_dest_state_3','log_archive_format',
                -- 'fal_client',
                'remote_login_passwordfile',
                'fal_server', 'standby_file_management','service_names',
                'dg_broker_config_file1','dg_broker_config_file2','dg_broker_start',
                'log_archive_min_succeed_dest','log_archive_max_processes'
                )
order by 1 ;

select protection_mode, force_logging, open_mode, database_role,switchover_status from v$database;

select dest_id, dest_name , status, error from v$archive_dest where dest_name in ('LOG_ARCHIVE_DEST_1','LOG_ARCHIVE_DEST_2','LOG_ARCHIVE_DEST_3');

spool off;
exit;

select process,status from v$managed_standby;

