-- PCT_OF_TOTAL       NUM_ROWS SEGMENT_TYPE       OWNER  SEGMENT_NAME

set verify off feedback off echo off
set trimspool on trimout on linesize 200
set pagesize 999

column gbytes format 999999.99
column pct_of_total format 999.99
column num_rows format 9999999999999
column owner format a14
column segment_type format a12
column segment_name format a60

spool &1 APPEND

select name as "DataBase", to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "CurrDate" from v$database;

prompt

select * from
(
    select s.bytes/1024/1024/1024 AS GBytes,
           100*s.bytes/(select sum(bytes) from dba_segments) as PCT_OF_TOTAL,
           t.num_rows,
           s.segment_type,
           cast(s.owner as varchar2(14)) as owner,
           decode(s.segment_type, 'LOBSEGMENT', (select cast(l.owner||'.'||l.table_name||'.'||l.column_name as varchar2(50))
                                                   from dba_lobs l 
                                                  where s.owner = l.owner 
                                                    and s.segment_name=l.segment_name), s.segment_name ) as segment_name
      from dba_segments s
           left outer join dba_tables t
              on     s.owner  = t.owner
                 and s.segment_name = t.table_name
                 and s.segment_type = 'TABLE'
    order by 1 desc,2,3
)
where rownum <= 20
/

set pagesize 0
select substr(rpad(dummy,123,'-'),2) from dual;
select substr(rpad(dummy,123,'-'),2) from dual;

spool off

