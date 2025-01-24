BEGIN
   execute immediate 'DROP TABLE PROD.WORKTABLE';

EXCEPTION   
   WHEN OTHERS THEN
      null;
END;
/

CREATE TABLE PROD.WORKTABLE(TABLE_NUM NUMBER,
                            TABLE_NAME VARCHAR2(30),
                            TABLE_SIZE NUMBER) TABLESPACE DATA;

INSERT into PROD.WORKTABLE                     
select rownum TABLE_NUM, t1.* from
   (select segment_name TABLE_NAME, bytes/1024/1024/1024 TABLE_SIZE
      from dba_segments 
      where owner='PROD' and segment_type='TABLE' and 
      tablespace_name IN ('DATA','DATA2','DATA3','DATA4','DATA5') and 
      segment_name != 'WORKTABLE' order by bytes desc) t1;

commit;