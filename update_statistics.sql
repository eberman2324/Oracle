spool /boraw1du01/aetna/scripts/maint/output1.out;

prompt 'Connecting as sysdba';
connect / as sysdba;

prompt 'dbms_stats for BENENG';
exec dbms_stats.gather_schema_stats(ownname=>'BENENG', estimate_percent=>20, cascade=>TRUE);
prompt 'dbms_stats for BENENG completed';

prompt 'dbms_stats for FINEOS_APP';
exec dbms_stats.gather_schema_stats(ownname=>'FINEOS_APP', estimate_percent=>20, cascade=>TRUE);
prompt 'dbms_stats for FINEOS_APP completed;

prompt 'dbms_stats for WKAB10';
exec dbms_stats.gather_schema_stats(ownname=>'WKAB10', estimate_percent=>20, cascade=>TRUE);
prompt 'dbms_stats for WKAB10 completed';

spool off;

exit;
