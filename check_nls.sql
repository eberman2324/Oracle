set echo on
set lines 100
column value 		format a40
column parameter 	format a30

spool check_nls_${ORACLE_SID}.outt

select * from nls_database_parameters where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');

spool off;
exit;
