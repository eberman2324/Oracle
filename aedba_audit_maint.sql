-- Create table: NOLOGGING and COMPRESS FOR DIRECT_LOAD OPERATIONS
CREATE TABLE AEDBA.AEDBA_DB_AUDIT_ARCHIVE
(
    OS_USERNAME        VARCHAR2(255)                   NULL,
    USERNAME           VARCHAR2(30)                    NULL,
    USERHOST           VARCHAR2(128)                   NULL,
    TERMINAL           VARCHAR2(255)                   NULL,
    TIMESTAMP          DATE                            NULL,
    OWNER              VARCHAR2(30)                    NULL,
    OBJ_NAME           VARCHAR2(128)                   NULL,
    ACTION             NUMBER                      NOT NULL,
    ACTION_NAME        VARCHAR2(28)                    NULL,
    NEW_OWNER          VARCHAR2(30)                    NULL,
    NEW_NAME           VARCHAR2(128)                   NULL,
    OBJ_PRIVILEGE      VARCHAR2(16)                    NULL,
    SYS_PRIVILEGE      VARCHAR2(40)                    NULL,
    ADMIN_OPTION       VARCHAR2(1)                     NULL,
    GRANTEE            VARCHAR2(30)                    NULL,
    AUDIT_OPTION       VARCHAR2(40)                    NULL,
    SES_ACTIONS        VARCHAR2(19)                    NULL,
    LOGOFF_TIME        DATE                            NULL,
    LOGOFF_LREAD       NUMBER                          NULL,
    LOGOFF_PREAD       NUMBER                          NULL,
    LOGOFF_LWRITE      NUMBER                          NULL,
    LOGOFF_DLOCK       VARCHAR2(40)                    NULL,
    COMMENT_TEXT       VARCHAR2(4000)                  NULL,
    SESSIONID          NUMBER                      NOT NULL,
    ENTRYID            NUMBER                      NOT NULL,
    STATEMENTID        NUMBER                      NOT NULL,
    RETURNCODE         NUMBER                      NOT NULL,
    PRIV_USED          VARCHAR2(40)                    NULL,
    CLIENT_ID          VARCHAR2(64)                    NULL,
    ECONTEXT_ID        VARCHAR2(64)                    NULL,
    SESSION_CPU        NUMBER                          NULL,
    EXTENDED_TIMESTAMP TIMESTAMP(6) WITH TIME ZONE     NULL,
    PROXY_SESSIONID    NUMBER                          NULL,
    GLOBAL_UID         VARCHAR2(32)                    NULL,
    INSTANCE_NUMBER    NUMBER                          NULL,
    OS_PROCESS         VARCHAR2(16)                    NULL,
    TRANSACTIONID      RAW(8)                          NULL,
    SCN                NUMBER                          NULL,
    SQL_BIND           NVARCHAR2(2000)                 NULL,
    SQL_TEXT           NVARCHAR2(2000)                 NULL,
    OBJ_EDITION_NAME   VARCHAR2(30)                    NULL
)
ORGANIZATION HEAP
TABLESPACE TOOLS
NOLOGGING
PCTUSED 0
INITRANS 1
MAXTRANS 255
STORAGE(BUFFER_POOL DEFAULT)
PARALLEL(DEGREE 3 INSTANCES 1)
NOCACHE
NOROWDEPENDENCIES
COMPRESS FOR DIRECT_LOAD OPERATIONS
/



CREATE OR REPLACE PACKAGE BODY AEDBA.aedba_audit_maint
is
   procedure audit_archive_purge
   is
   -- Grab the time we started
   l_run_date timestamp := systimestamp;

   begin
      -- Use insert append so that data will be compressed
      insert /*+ append */ into aedba.aedba_db_audit_archive
      select *
        from dba_audit_trail
      where  timestamp < l_run_date;

      delete
        from sys.aud$
       where from_tz(ntimestamp#,'00:00') at local < l_run_date;
      commit;
   exception
      when others then
      begin
         -- Roll back so we can re-try this block again later
         rollback;
         dbms_output.put_line('Error: ' || SQLCODE || ' Msg: ' || SUBSTR(SQLERRM, 1, 64));

         -- Re-throw the error so we'll get a failure.
         raise;
      end;
   end;

end aedba_audit_maint;

delete from sys.aud$
        