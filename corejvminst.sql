Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/corejvminst__&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

-- Start of File corejvminst.sql
 set serveroutput on
 set echo on
 startup mount 
 alter system set "_system_trig_enabled" = false scope=memory; 
 alter database open; 
 select owner, status, count(*) from all_objects
     where object_type like '%JAVA%' group by owner, status;
 create or replace java system
 / 
 shutdown immediate
 set echo off
 spool off
 exit 
 -- End of File corejvminst.sql
