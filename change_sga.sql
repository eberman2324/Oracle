spool change_sga.out

set echo on term on line 100

alter system set sga_max_size=64G scope=spfile;
alter system set sga_target=64G scope=spfile; 
alter system set pga_aggregate_target=16G scope=spfile;
alter system reset LOG_ARCHIVE_DEST_2 scope=spfile;
--alter system reset pga_aggregate_limit scope=spfile; 
---CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/oraexport/u01/datapump/'


spool off
