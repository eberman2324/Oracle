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
column  force_logging   format a14
column  open_mode       format a16
column  protection_mode format a20
column  database_role   format a14
column  name            format a30
column  value           format a100

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

