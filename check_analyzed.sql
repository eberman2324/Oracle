select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'WKAB10'
order by 4 desc

desc dba_tables


select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'VRSC' and TABLE_NAME like '%MCS_%'
order by last_analyzed desc

select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'VRSC' 
order by 3 desc

select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'VRSC' and TABLE_NAME  = 'FMS_SITE_CONT_SVCS'


select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
order by 4 desc


select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'LX_DAILY'
order by 4 desc


select * from dba_TAB_STATS_HISTORY where table_name  = 'T_PERSON' order by 5 desc
select * from dba_TAB_STATS_HISTORY where table_name  = 'T_EMPLOYEE' order by 5 desc
select * from dba_TAB_STATS_HISTORY where table_name  = 'T_ADDRESS' order by 5 desc

EXEC DBMS_STATS.gather_table_stats('WKAB10', 'T_DIVISION', estimate_percent => 20);
EXEC DBMS_STATS.gather_table_stats('WKAB10', 'T_UNION', estimate_percent => 20);
EXEC DBMS_STATS.gather_table_stats('WKAB10', 'T_GENDER', estimate_percent => 20);
EXEC DBMS_STATS.gather_table_stats('WKAB10', 'T_EMP_INFO', estimate_percent => 20);

EXEC DBMS_STATS.gather_table_stats('WKAB10', 'T_ADDRESS', estimate_percent => 20);
EXEC DBMS_STATS.gather_table_stats('DRWKAB', 'WKAB_TASK_INSTANCE_MV', estimate_percent => 20);


Mikes---------->
   exec dbms_stats.gather_table_stats(OWNNAME=>'WKAB10', tabname=>'T_WKAB_LOOKUP', method_opt=> 'FOR ALL COLUMNS SIZE 1', force=>TRUE, no_invalidate=>FALSE);


   exec dbms_stats.gather_index_stats(ownname=>'WKAB10', indname=>'PK_REQUEST',no_invalidate=>false, force=>true);

exec dbms_stats.gather_index_stats(ownname=>'WKAB10', indname=>'TASK_INSTANCE_IDX2', no_invalidate=>false, force=>true);


exec dbms_stats.gather_table_stats(OWNNAME=>'PIHMS', tabname=>'CLP_CLIENT_LEAVE_POLICY', method_opt=> 'FOR ALL COLUMNS SIZE 1', force=>TRUE, no_invalidate=>FALSE);


exec dbms_stats.gather_table_stats(OWNNAME=>'DRWKAB', tabname=>'WKAB_TASK_INSTANCE_MV', method_opt=> 'FOR ALL COLUMNS SIZE 1', force=>TRUE, no_invalidate=>FALSE);



