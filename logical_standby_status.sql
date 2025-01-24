set pagesize 1024
column STATUS format A30 WORD_WRAP
column EVENT_PART format A30 WORD_WRAP
column SPID format A15 WORD_WRAP
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';

PROMPT ===================================== Standby Status ==========================================================
select primary_dbid, session_id, state, cast(realtime_apply as varchar2(5))as realtime_apply from V$LOGSTDBY_STATE;


PROMPT ===================================== Standby Latency =========================================================
select (sysdate - applied_time)*3600*24 seconds_latency,APPLIED_TIME,RESTART_TIME, LATEST_TIME,MINING_TIME, RESETLOGS_ID from V$LOGSTDBY_PROGRESS p;
PROMPT ===============================================================================================================

PROMPT ===================================== Standby Processes =======================================================

select  cast( SID || ',' || SERIAL# as varchar2(15)) as sidserial,
        LOGSTDBY_ID, SPID, cast(TYPE as varchar2(15)) as type,
        decode(STATUS_CODE, 16111, 'SQL Apply: Initializing', 
                            16112, 'SQL Apply: Cleaning Up',
                            16116, 'SQL Apply: Idle',
                            16117, 'SQL Apply: Busy',
                            16110, 'Applier: User proc',
                            16113, 'Applier: Applying DML',
                            16114, 'Applier: Applying DDL',
                            16115, 'Coordinator: Loading Dict',
                            16243, 'Builder: Paging out',
                            16240, 'Reader: Idle waiting log',
                            16241, 'Reader: Idle waiting gap',
                            16242, 'Reader: Processing log',
                            'Unknown') as status_code,
         cast(STATUS as varchar2(50)) as status
from V$LOGSTDBY_PROCESS
order by 2
/

PROMPT ======================================== Last 10 events =======================================================

select * from (select event_time, status_code, cast(status as varchar2(256)) as status, cast(event as varchar2(100)) as event_part , cast(XIDUSN ||','|| XIDSLT||','||XIDSQN as varchar2(25)) as XID
  from DBA_LOGSTDBY_EVENTS order by event_time desc) where rownum <= 10;

--select name, cast(value as varchar2(20)) as value from V$LOGSTDBY_STATS order by 1;

PROMPT ======================================== Current Transactions =================================================
select * from V$LOGSTDBY_TRANSACTION;

