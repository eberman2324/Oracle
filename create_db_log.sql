set echo on

spool create_db_log.out

create table db_log (
        L_ID number,
        L_TS date,
        L_COMMENT varchar2(50)
        )
--tablespace users
;

insert into db_log values (1, sysdate, 'This is Line 1');
commit;

@check_log

spool off;
exit;

