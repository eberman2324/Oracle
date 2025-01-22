connect sys/locked99999@TSTDB12_xorangw1d as sysdba;
set echo on
alter system set standby_file_management = 'AUTO';
connect sys/locked99999@TSTDB12_xoragdbw1d as sysdba;
alter system set standby_file_management = 'AUTO';
