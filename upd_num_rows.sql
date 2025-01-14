set verify off serveroutput on size unlimited

declare
   sql_stmt varchar2(3000);

cursor tab is
    select distinct table_owner,
           table_name
    from   aedba.table_growth_history
    where  num_rows = -1
    and    trunc(timestamp) = (select max(trunc(timestamp)) from aedba.table_growth_history);  --Latest Run

BEGIN

FOR tab_rec IN tab

LOOP

BEGIN

    sql_stmt:='update aedba.table_growth_history '||
    'set num_rows = (select /*+ index_ffs (x) PARALLEL(6) */ count(*) from '||
    tab_rec.table_owner||'.'||tab_rec.table_name||
    ' x ) where table_name = '||chr(39)||tab_rec.table_name||chr(39)||
    ' and num_rows = -1 and trunc(timestamp) = (select max(trunc(timestamp)) from aedba.table_growth_history)';

    EXECUTE IMMEDIATE sql_stmt;

    exception when others then
       dbms_output.put_line('Error updating table '||tab_rec.table_name||' '||SQLERRM);

END;

commit;

END LOOP;

END;

/

