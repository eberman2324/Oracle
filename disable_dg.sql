set echo on trimspool on

spool disable_dg.out

alter system set dg_broker_start=false scope=both;
alter system set log_archive_dest_2='' scope=both;
alter system set log_archive_dest_3='' scope=both;
alter system set log_archive_config='' scope=both;
alter system set log_archive_dest_state_2=DEFER SCOPE=BOTH;
alter system set log_archive_dest_state_3=DEFER SCOPE=BOTH;
alter system set fal_server='' scope=both;

spool off;

