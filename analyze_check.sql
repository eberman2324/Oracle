select t.owner||'.'||table_name table_name,
t.num_rows, to_char(t.last_analyzed,'MM/DD HH24:MI:SS'),last_analyzed
from dba_tables t
where owner = 'SYSADM'
order by 4 desc