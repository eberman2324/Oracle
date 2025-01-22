

REM
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.card' spool_extension FROM sys.dual;
column output new_value dbname
SELECT '___'||value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on

-- spool card__&&dbname&&timestamp&&suffix

Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^




REM Cardinality report on tables and indexes.
REM STATISTICS NEED TO BE COMPUTED FOR THIS SCRIPT
REM TO EXECUTE

REM ****************************************************************************************
REM ****************************************************************************************
REM ****************************************************************************************

undefine owner
undefine table
undefine 1
undefine 2
 
def owner   = &&1
def table   = &&2

spool &&table&&dbname&&timestamp&&suffix

--@stdhdr

--set linesize 120
set linesize 140

set pagesize 83
set feedback off
set verify off

REM ****************************************************************************************

ttitle off
ttitle center -
        'Statistics for columns of table &&owner..&&table' -
       skip 2

break on column_name on num_distinct on column_id on data_length on nullable on data_type

--col column_name         heading 'Column Name'           format a20
col column_name         heading 'Column Name'           format a30
col nullable            heading 'Null ?'                format a1
col column_id           heading 'Seq'                   format 999
col num_distinct        heading 'Number|Distinct'       format 999999999
--col index_name          heading 'Index Name'            format a25
col index_name          heading 'Index Name'            format a30
col column_position     heading 'Pos'                   format 999
col data_type           heading 'Type'                  format a14
col data_length         heading 'Max|Len'               format 9999

SELECT  a.column_name, 
                a.nullable,
                a.column_id, 
                a.data_type,
                a.data_length,
                a.num_distinct,
                b.index_name, 
                b.column_position 
FROM            dba_tab_columns a, 
                dba_ind_columns b
WHERE   a.owner = upper('&&owner') and
                b.table_owner = upper('&&owner') and
                a.table_name = upper('&&table') and
                b.table_name = upper('&&table') and
                a.column_name = b.column_name
UNION ALL
SELECT  column_name, 
                a.nullable,
                column_id, 
                a.data_type,
                a.data_length,
                num_distinct,
                ' ', 
                0
FROM            dba_tab_columns a
WHERE   owner = upper('&&owner') and
                table_name = upper('&&table') and
                not exists (    SELECT  * 
                                        FROM            dba_ind_columns 
                                        WHERE   table_owner = upper('&&owner') and
                                                        table_name = upper('&&table') and
                                                        column_name = a.column_name)
ORDER BY column_id;

REM ****************************************************************************************

col num_rows            heading 'Nbr Rows'              format 999999999
col blocks              heading 'Blocks'                format 999999999
col empty_blocks        heading 'Empty|Blocks'          format 999999999
col avg_space           heading 'Avg Free|Space'        format 999999999
col chain_cnt           heading '# Chains'              format 99999999
col avg_row_len         heading 'Avg|Len'               format 99999

TTitle  center -
        'Statistics For Table &owner..&table' -
        skip 2

SELECT  num_rows,
                blocks,
                empty_blocks,
                avg_space,
                chain_cnt,
                avg_row_len
FROM            dba_tables
WHERE   owner = upper('&&owner') and
                table_name = upper('&&table');
clear breaks

REM ****************************************************************************************

set newpage 0

ttitle off
ttitle center -
        'Statistics for indexes of table &&owner..&&table' -
        skip 2

--column index_name format A25
column index_name format A30
--column column_name format A25
column column_name format A30
column column_position format 999 heading 'Pos'
column uniq format a5

break on index_name skip 1

select 
	C.index_name,
	substr(I.uniqueness,1,1) uniq, 
	C.column_name,
	C.column_position , 
	T.NUM_DISTINCT
from  
	all_ind_columns C
	,all_indexes     I
     	,all_tab_columns T
where 
	C.table_owner = upper('&&owner')
	and  C.table_name  = upper('&&table')
	and  C.index_owner = I.owner
	and  C.index_name  = I.index_name
	and  C.table_name = T.table_name
	and  C.column_name = T.column_name
order by 
	2 desc,1,4
;

set newpage 1

--col name                for     a20             head 'Index'                    just l
--col name                for     a26             head 'Index'                    just l
col name                for     a30             head 'Index'                    just l
col ind_type            for     a08             head 'Type  '                   just l
col uniq                for     a04             head 'Uniqueness'               just l
col alloc               for     999,990         head 'Allocated|Blocks'         just l
col blevel              for     990             head 'B|Lebel'                  just l
col leafblks            for     999,990         head 'Leaf|Blocks'              just l
col avglfblks           for     999,990         head 'Avg|Leaf|Blocks|per key'  just l
col avgdtblks           for     999,990         head 'Avg|Data|Blocks|per key'  just l
col clustering          for     999,999,990         head 'Clustering'               just l
col nrows               for     99999,990       head 'Number|of rows'           just l
col distkeys            for     99999,990       head 'Distinct|Keys'            just l
col pctclust            for     990.09          head 'Pct|Cluster|for Rows'     just l

select
--        c.owner||'.'||c.index_name name,
        c.index_name name,
	c.index_type ind_type,
        substr(uniqueness,1,1) uniq,
        b.blocks alloc,
        c.blevel blevel,
        c.leaf_blocks leafblks,
        c.avg_leaf_blocks_per_key avglfblks,
        c.avg_data_blocks_per_key avgdtblks,
        c.distinct_keys distkeys,
        d.num_rows nrows,
        c.clustering_factor clustering,
        100 - (((d.num_rows - c.clustering_factor) / d.num_rows ) * 100) pctclust
from
        dba_segments b,
        dba_indexes c,
        dba_tables d
where
	d.table_name = upper('&&table') and
        b.segment_type = 'INDEX' AND
        b.owner not in ('SYS','SYSTEM') AND
        b.owner = c.owner AND
        c.table_name = d.table_name AND
        c.index_name = b.segment_name
order by 2 desc,1
--order by
--        1
--      11 desc,
--      9 desc
/


REM Clear variables

undefine owner
undefine table
undefine 1
undefine 2
ttitle off
clear column
clear breaks
 

REM End of Script

-- @$rpt/stdhdr
-- @%sqlpath%\stdhdr

set heading off
set newpage 1
SELECT
	substr(to_char(sysdate, 'DD-MON-YY HH24:MI:SS'),1,25) "Time Stamp",
	substr(instance,1,10) "Oracle SID"
FROM
	v$thread
;

set heading on


spool off

