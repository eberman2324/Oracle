-- NAME: NONRACDIAG.SQL
-- SYS OR INTERNAL USER, CATPARR.SQL ALREADY RUN, PARALLEL QUERY OPTION ON
-- ------------------------------------------------------------------------
-- AUTHOR:
-- Michael Polaski & Ken Jensen - Oracle Support Services
-- Copyright 2002, Oracle Corporation
-- ------------------------------------------------------------------------
-- PURPOSE:
-- This script is intended to provide a user friendly guide to troubleshoot
-- Non-RAC hung sessions or slow performance scenerios. The script includes
-- information to gather a variety of important debug information to determine
-- the cause of a non-RAC session level hang. The script will create a file
-- called nonracdiag_.out in your local directory while dumping hang analyze
-- dumps in the user_dump_dest(s) and background_dump_dest(s).
-- 
-- ------------------------------------------------------------------------
-- DISCLAIMER:
-- This script is provided for educational purposes only. It is NOT
-- supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts on a test instance initially.
-- ------------------------------------------------------------------------
-- Script output is as follows:

set echo off
set feedback off
column timecol new_value timestamp
column spool_extension new_value suffix
select to_char(sysdate,'mmdd_hhmi') timecol,
'.out' spool_extension from sys.dual;
column output new_value dbname
select value || '_' output
from v$parameter where name = 'db_name';
spool nonracdiag_&&dbname&&timestamp&&suffix
set lines 200
set pagesize 35
set trim on
set trims on
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set timed_statistics = true;
set feedback on
select to_char(sysdate) time from dual;

set numwidth 5
column host_name format a20 tru
select instance_number, instance_name, host_name, version, status, startup_time
from v$instance
order by instance_number;

set echo on

-- WAIT CHAINS
-- 11.x+ Only (This will not work in < v11
-- See Note 1428210.1 for instructions on interpreting.
set pages 1000
set lines 120
set heading off
column w_proc format a50 tru
column instance format a20 tru
column inst format a28 tru
column wait_event format a50 tru
column p1 format a16 tru
column p2 format a16 tru
column p3 format a15 tru
column Seconds format a50 tru
column sincelw format a50 tru
column blocker_proc format a50 tru
column waiters format a50 tru
column chain_signature format a100 wra
column blocker_chain format a100 wra
SELECT *
FROM (SELECT 'Current Process: '||osid W_PROC, 'SID '||i.instance_name INSTANCE,
'INST #: '||instance INST,'Blocking Process: '||decode(blocker_osid,null,'<none>',blocker_osid)||
' from Instance '||blocker_instance BLOCKER_PROC,'Number of waiters: '||num_waiters waiters,
'Wait Event: ' ||wait_event_text wait_event, 'P1: '||p1 p1, 'P2: '||p2 p2, 'P3: '||p3 p3,
'Seconds in Wait: '||in_wait_secs Seconds, 'Seconds Since Last Wait: '||time_since_last_wait_secs sincelw,
'Wait Chain: '||chain_id ||': '||chain_signature chain_signature,'Blocking Wait Chain: '||decode(blocker_chain_id,null,
'<none>',blocker_chain_id) blocker_chain
FROM v$wait_chains wc,
v$instance i
WHERE wc.instance = i.instance_number (+)
AND ( num_waiters > 0
OR ( blocker_osid IS NOT NULL
AND in_wait_secs > 10 ) )
ORDER BY chain_id,
num_waiters DESC)
WHERE ROWNUM < 101;

-- Taking Hang Analyze dumps
-- This may take a little while...
oradebug setmypid
oradebug unlimit
oradebug hanganalyze 3
-- This part may take the longest, you can monitor bdump or udump to see if
-- the file is being generated.

-- WAITING SESSIONS:
-- The entries that are shown at the top are the sessions that have
-- waited the longest amount of time that are waiting for non-idle wait
-- events (event column). You can research and find out what the wait
-- event indicates (along with its parameters) by checking the Oracle
-- Server Reference Manual or look for any known issues or documentation
-- by searching Metalink for the event name in the search bar. Example
-- (include single quotes): [ 'buffer busy due to cache' ].
-- Metalink and/or the Server Reference Manual should return some useful
-- information on each type of wait event. The inst_id column shows the
-- instance where the session resides and the SID is the unique identifier
-- for the session (v$session). The p1, p2, and p3 columns will show
-- event specific information that may be important to debug the problem.
-- To find out what the p1, p2, and p3 indicates see the next section.
-- Items with wait_time of anything other than 0 indicate we do not know
-- how long these sessions have been waiting.
-- 
set numwidth 15
set heading on
column state format a7 tru
column event format a25 tru
column last_sql format a40 tru
select sw.sid, sw.state, sw.event, sw.seconds_in_wait seconds,
sw.p1, sw.p2, sw.p3, sa.sql_text last_sql
from v$session_wait sw, v$session s, v$sqlarea sa
where sw.event not in
('rdbms ipc message','smon timer','pmon timer',
'SQL*Net message from client','lock manager wait for remote message',
'ges remote message', 'gcs remote message', 'gcs for action', 'client message',
'pipe get', 'null event', 'PX Idle Wait', 'single-task message',
'PX Deq: Execution Msg', 'KXFQ: kxfqdeq - normal deqeue',
'listen endpoint status','slave wait','wakeup time manager')
and sw.seconds_in_wait > 0
and (sw.sid = s.sid) 
and (s.sid = sa.parsing_schema_id and s.sql_address = sa.address) 
order by seconds desc;

-- EVENT PARAMETER LOOKUP:
-- This section will give a description of the parameter names of the
-- events seen in the last section. p1test is the parameter value for
-- p1 in the WAITING SESSIONS section while p2text is the parameter
-- value for p3 and p3 text is the parameter value for p3. The
-- parameter values in the first section can be helpful for debugging
-- the wait event.
-- 
column event format a30 tru
column p1text format a25 tru
column p2text format a25 tru
column p3text format a25 tru
select distinct event, p1text, p2text, p3text
from v$session_wait sw
where sw.event not in ('rdbms ipc message','smon timer','pmon timer',
'SQL*Net message from client','lock manager wait for remote message',
'client message', 'pipe get', 'null event', 'PX Idle Wait', 'single-task message',
'PX Deq: Execution Msg', 'KXFQ: kxfqdeq - normal deqeue',
'listen endpoint status','slave wait','wakeup time manager','AQPC idle','Data Guard: Gap Manager',
'Data Guard: Timer','Space Manager: slave idle wait','VKRM Idle','VKTM Logical Idle Wait',
'heartbeat redo informer','pman timer','lreg timer','class slave wait','DIAG idle wait')
and seconds_in_wait > 0
order by event;

-- need to add the following waits to above: 

-- LOCK BLOCKERS:
-- This section will show us any sessions that are holding locks that
-- are blocking other users. The sid will be a unique identifier for
-- the session. The grant_level will show us how the lock is granted to
-- the user. The request_level will show us what status we are trying to
-- obtain.  The lockstate column will show us what status the lock is in.
-- The last column shows how long this session has been waiting.
-- 
set numwidth 5
column state format a16 tru;
column event format a30 tru;
select dl.inst_id, s.sid, p.spid, dl.eq_type,
decode(substr(dl.succ_req#,1,8),'KJUSERNL','Null','KJUSERCR','Row-S (SS)',
'KJUSERCW','Row-X (SX)','KJUSERPR','Share','KJUSERPW','S/Row-X (SSX)',
'KJUSEREX','Exclusive') as grant_level,
decode(substr(dl.total_req#,1,8),'KJUSERNL','Null','KJUSERCR','Row-S (SS)',
'KJUSERCW','Row-X (SX)','KJUSERPR','Share','KJUSERPW','S/Row-X (SSX)',
'KJUSEREX','Exclusive') as request_level,
decode(substr(dl.failed_req#,1,8),'KJUSERGR','Granted','KJUSEROP','Opening', 
'KJUSERCA','Canceling','KJUSERCV','Converting') as state,
s.sid, sw.event, sw.seconds_in_wait sec
from v$enqueue_stat dl, v$process p, v$session s, v$session_wait sw
where sw.wait_time = 0 
and (dl.inst_id = p.spid) 
and (p.spid = s.sid and p.addr = s.paddr) 
and (s.sid = sw.sid) 
order by sw.seconds_in_wait desc; 

-- LOCK WAITERS:
-- This section will show us any sessions that are waiting for locks that
-- are blocked by other users. The sid will be a unique identifier for
-- the session. The grant_level will show us how the lock is granted to
-- the user. The request_level will show us what status we are trying to
-- obtain.  The lockstate column will show us what status the lock is in.
-- The last column shows how long this session has been waiting.
-- 
set numwidth 5
column state format a16 tru;
column event format a30 tru;
select dl.inst_id, s.sid, p.spid, dl.eq_type,
decode(substr(dl.succ_req#,1,8),'KJUSERNL','Null','KJUSERCR','Row-S (SS)',
'KJUSERCW','Row-X (SX)','KJUSERPR','Share','KJUSERPW','S/Row-X (SSX)',
'KJUSEREX','Exclusive') as grant_level,
decode(substr(dl.total_req#,1,8),'KJUSERNL','Null','KJUSERCR','Row-S (SS)',
'KJUSERCW','Row-X (SX)','KJUSERPR','Share','KJUSERPW','S/Row-X (SSX)',
'KJUSEREX','Exclusive') as request_level,
decode(substr(dl.failed_req#,1,8),'KJUSERGR','Granted','KJUSEROP','Opening', 
'KJUSERCA','Cancelling','KJUSERCV','Converting') as state,
s.sid, sw.event, sw.seconds_in_wait sec
from v$enqueue_stat dl, v$process p, v$session s, v$session_wait sw
where sw.wait_time = 0 
and (dl.inst_id = p.spid) 
and (p.spid = s.sid and p.addr = s.paddr) 
and (s.sid = sw.sid) 
order by sw.seconds_in_wait desc; 

-- LOCAL ENQUEUES:
-- This section will show us if there are any local enqueues. The sid will be a
-- unique identifier and the addr column will show the lock address. The type
-- will show the lock type. The id1 and id2 columns will show specific
-- parameters for the lock type.
-- 
set numwidth 12
column event format a12 tru
select l.con_id, l.sid, l.addr, l.type, l.id1, l.id2,
decode(l.block,0,'blocked',1,'blocking',2,'global') block,
sw.event, sw.seconds_in_wait sec
from v$lock l, v$session_wait sw
where (l.sid = sw.sid) 
and l.block in (0,1)
order by l.type, l.sid, l.sid;

-- LATCH HOLDERS:
-- If there is latch contention or 'latch free' wait events in the WAITING
-- SESSIONS section we will need to find out which proceseses are holding
-- latches. The sid will be a unique identifier and the username column
-- will show the session's username. The os_user column will show the os
-- user that the user logged in as. The name column will show us the type
-- of latch being waited on. You can search Metalink for the latch name in
-- the search bar. Example (include single quotes):
-- [ 'library cache' latch ]. Metalink should return some useful information
-- on the type of latch.
-- 
set numwidth 5
select distinct lh.sid, s.sid, s.username, s.osuser, p.username, lh.name
from v$latchholder lh, v$session s, v$process p
where (lh.sid = s.sid) 
and (s.sid = p.pid and s.paddr = p.addr) 
order by lh.sid, s.sid;

-- LATCH STATS:
-- This view will show us latches with less than optimal hit ratios
-- The inst_id will show us the instance for the particular latch. The
-- latch_name column will show us the type of latch. You can search Metalink
-- for the latch name in the search bar. Example (include single quotes):
-- [ 'library cache' latch ]. Metalink should return some useful information
-- on the type of latch. The hit_ratio shows the percentage of time we
-- successfully acquired the latch.
-- 
column name format a30 tru
select con_id, name, addr, hash,
round((gets-misses)/decode(gets,0,1,gets),3) hit_ratio,
round(sleeps/decode(misses,0,1,misses),3) "SLEEPS/MISS"
from v$latch
where round((gets-misses)/decode(gets,0,1,gets),3) < .99
and gets != 0
order by round((gets-misses)/decode(gets,0,1,gets),3);

-- No Wait Latches:
-- 
select con_id, name, addr, hash,
round((immediate_gets/(immediate_gets+immediate_misses)), 3) hit_ratio,
round(sleeps/decode(immediate_misses,0,1,immediate_misses),3) "SLEEPS/MISS"
from v$latch
where round((immediate_gets/(immediate_gets+immediate_misses)), 3) < .99
and immediate_gets + immediate_misses > 0
order by round((immediate_gets/(immediate_gets+immediate_misses)), 3);

-- RESOURCE USAGE
-- This section will show how much of our resources we have used.
-- 
set numwidth 8
select con_id, resource_name, current_utilization, max_utilization, 
initial_allocation
from v$resource_limit
where max_utilization > 0
order by con_id, resource_name; 

-- LOCK CONVERSION DETAIL:
-- This view shows the types of lock conversion being done in the database.
-- 
select * from v$lock_activity;

-- INITIALIZATION PARAMETERS:
-- Non-default init parameters for the database.
-- 
set numwidth 5
column name format a30 tru
column value format a50 wra
column description format a60 tru
select con_id, name, value, description 
from v$parameter
where isdefault = 'FALSE'
order by con_id, name; 

-- TOP 10 WAIT EVENTS ON SYSTEM
-- This view will provide a summary of the top wait events in the db.
-- 
set numwidth 10
column event format a25 tru
select con_id, event, time_waited, total_waits, total_timeouts 
from (select con_id, event, time_waited, total_waits, total_timeouts
from v$system_event where event not in ('rdbms ipc message','smon timer','pmon timer', 
'SQL*Net message from client','lock manager wait for remote message',
'client message', 'pipe get', 'null event', 'PX Idle Wait', 'single-task message',
'PX Deq: Execution Msg', 'KXFQ: kxfqdeq - normal deqeue',
'listen endpoint status','slave wait','wakeup time manager','Space Manager: slave idle',
'class slave wait','DIAG idle wait','VKRM Idle','dispatcher timer','lreg timer','watchdog main loop',
'pman timer','shared server idle wait')
order by time_waited desc)
where rownum < 11
order by time_waited desc;

-- SESSION/PROCESS REFERENCE:
-- This section is very important for most of the above sections to find out
-- which user/os_user/process is identified to which session/process.
-- 
set numwidth 7
column event format a30 tru
column program format a50 tru
column username format a15 tru
select s.sid, s.serial#, p.pid, p.spid, p.program, s.username,
p.username os_user, sw.event, sw.seconds_in_wait sec
from v$process p, v$session s, v$session_wait sw
where (p.addr = s.paddr)
and (s.sid = sw.sid)
order by p.pid, s.sid;

-- SYSTEM STATISTICS:
-- All System Stats with values of > 0. These can be referenced in the
-- Server Reference Manual
-- 
set numwidth 5
column name format a60 tru
column value format 9999999999999999999999999
select con_id, name, value 
from v$sysstat
where value > 0
order by con_id, name; 

-- CURRENT SQL FOR WAITING SESSIONS:
-- Current SQL for any session in the WAITING SESSIONS list
-- 
set numwidth 5
column sql format a80 wra
select sw.sid, sw.seconds_in_wait sec, sa.sql_text sql
from v$session_wait sw, v$session s, v$sqlarea sa
where sw.sid = s.sid (+)
and s.sql_address = sa.address
and sw.event not in ('rdbms ipc message','smon timer','pmon timer', 
'SQL*Net message from client', 'lock manager wait for remote message', 
'client message', 'pipe get', 'null event', 'PX Idle Wait', 'single-task message',
'PX Deq: Execution Msg', 'KXFQ: kxfqdeq - normal deqeue',
'listen endpoint status','slave wait','wakeup time manager')
and sw.seconds_in_wait > 0
order by sw.seconds_in_wait desc;

-- WAIT CHAINS
-- 11.x+ Only (This will not work in < v11
-- See Note 1428210.1 for instructions on interpreting.
set pages 1000
set lines 120
set heading off
column w_proc format a50 tru
column instance format a20 tru
column inst format a28 tru
column wait_event format a50 tru
column p1 format a16 tru
column p2 format a16 tru
column p3 format a15 tru
column seconds format a50 tru
column sincelw format a50 tru
column blocker_proc format a50 tru
column waiters format a50 tru
column chain_signature format a100 wra
column blocker_chain format a100 wra
SELECT *
FROM (SELECT 'Current Process: '||osid W_PROC, 'SID '||i.instance_name INSTANCE,
'INST #: '||instance INST,'Blocking Process: '||decode(blocker_osid,null,'<none>',blocker_osid)||
' from Instance '||blocker_instance BLOCKER_PROC,'Number of waiters: '||num_waiters waiters,
'Wait Event: ' ||wait_event_text wait_event, 'P1: '||p1 p1, 'P2: '||p2 p2, 'P3: '||p3 p3,
'Seconds in Wait: '||in_wait_secs Seconds, 'Seconds Since Last Wait: '||time_since_last_wait_secs sincelw,
'Wait Chain: '||chain_id ||': '||chain_signature chain_signature,'Blocking Wait Chain: '||decode(blocker_chain_id,null,
'<none>',blocker_chain_id) blocker_chain
FROM v$wait_chains wc,
v$instance i
WHERE wc.instance = i.instance_number (+)
AND ( num_waiters > 0
OR ( blocker_osid IS NOT NULL
AND in_wait_secs > 10 ) )
ORDER BY chain_id,
num_waiters DESC)
WHERE ROWNUM < 101;

-- Taking Hang Analyze dumps
-- This may take a little while...
oradebug setmypid
oradebug unlimit
oradebug hanganalyze 3
-- This part may take the longest, you can monitor bdump or udump to see
-- if the file is being generated.

set echo off

select to_char(sysdate) time from dual;

spool off

-- ---------------------------------------------------------------------------
Prompt;
Prompt nonracdiag output files have been written to:;
Prompt;
Prompt alert log and trace files are located in:;
column host_name format a12 tru
column name format a20 tru
column value format a60 tru
select distinct i.host_name, p.name, p.value
from v$instance i, v$parameter p
where p.num = i.instance_number (+)
and p.name like '%_dump_dest'
and p.name != 'core_dump_dest';

-- ########################################
-- Collect data from Active Session History
-- ########################################

set serverout on size unl;
set lines 5000
set trimspool on

set term off echo off
set feedback off

column ash_csv_file new_value ash_csv_file format a128;
column ash_csv_out_filename new_value ash_csv_out_filename format a128;
column diag_zip_file new_value diag_zip_file format a128;
column nonracdiag_out_file new_value nonracdiag_out_file format a128;
column hanganalyze_trc_file new_value hanganalyze_trc_file format a256;
select 
  'ash_csv_' || '&&dbname' || '' || '&&timestamp' || '.csv' ash_csv_file,
  'ash_csv_' || '&&dbname' || '' || '&&timestamp' || '.csv.out' ash_csv_out_filename, 
  'nonracdiag_' || '&&dbname' || '' || '&&timestamp' || '.zip' diag_zip_file,
  'nonracdiag_' || '&&dbname' || '' || '&&timestamp' || '&&suffix' nonracdiag_out_file,
  (select value from v$diag_info where name = 'Default Trace File') as hanganalyze_trc_file
from dual;
-- close the trace file that will be moved to zip file
oradebug close_trace

set term on echo off;
prompt
prompt =============================================
prompt To collect Active Session History data for diagnostic,
prompt Please provide the specific time period during which the issue occurred (YYYY-MM-DD HH24:MI:SS),
prompt If not provided, the data within the last hour will be collected:
prompt
define sample_time_from = '&sample_time_from';
define sample_time_to = '&sample_time_to';
prompt
-- 
var sample_time_from varchar2(40);
var sample_time_to varchar2(40);
var prev_hour_time varchar2(40);
var curr_hour_time varchar2(40);
var ash_tbl_name varchar2(128);
var c_time_fmt varchar2(40);
var csv_record_count number;
var ash_csv_file varchar2(128);
var hanganalyze_trc_file  varchar2(256);
var nonracdiag_out_file  varchar2(128);
exec :sample_time_from := '&&sample_time_from';
exec :sample_time_to := '&&sample_time_to';
exec :ash_tbl_name := 'GV$ACTIVE_SESSION_HISTORY';
exec :c_time_fmt := 'YYYY-MM-DD HH24:MI:SS';
exec :ash_csv_file := '&&ash_csv_file';
exec :hanganalyze_trc_file := '&&hanganalyze_trc_file';
exec :nonracdiag_out_file := '&&nonracdiag_out_file';

declare
    v_curr_hour date := trunc(sysdate, 'mi');
    v_prev_hour date := trunc(sysdate - interval '1' hour, 'mi');
    v_from_date date := null;
    v_to_date   date := null;
begin 
    --
    begin 
        if :sample_time_from is null then
            v_from_date := v_prev_hour;
        else
            v_from_date := to_date(:sample_time_from, :c_time_fmt);
        end if;
    exception
        when others then
            v_from_date := v_prev_hour;
    end;
    --
    begin 
        if :sample_time_to is null then
            v_to_date := v_from_date + interval '1' hour;
        else
            v_to_date := to_date(:sample_time_to, :c_time_fmt);
        end if;
    exception
        when others then
            v_to_date := v_from_date + interval '1' hour;
    end;
    --
    :sample_time_from := to_char(v_from_date, :c_time_fmt);
    :sample_time_to := to_char(v_to_date, :c_time_fmt);
    :prev_hour_time := to_char(v_prev_hour, :c_time_fmt);
    :curr_hour_time := to_char(v_curr_hour, :c_time_fmt);
    -- 
    if not (v_from_date >= v_prev_hour and v_from_date <= v_curr_hour and v_to_date >= v_prev_hour and v_to_date <= v_curr_hour) then
        :ash_tbl_name := 'DBA_HIST_ACTIVE_SESS_HISTORY';
    end if;
    -- 
end;
/

-- #########################
-- spool 
set term off echo off;

spool &&ash_csv_file
declare
    v_sql         varchar2(4000);
    -- 
    function qry2csv(P_QUERY in VARCHAR2) return NUMBER
    is
        L_THECURSOR INTEGER default DBMS_SQL.OPEN_CURSOR;
        L_COLUMNVALUE_CHAR VARCHAR2(4000);
        L_COLUMNVALUE_DATE DATE;
        L_COLUMNVALUE_NUMBER NUMBER;
        
        L_STATUS INTEGER;
        L_COLCNT NUMBER := 0;
        L_SEPARATOR VARCHAR2(1);
        L_DESCTBL DBMS_SQL.DESC_TAB;
        --
        R_COUNT  NUMBER := 0;
        -- 
        DT_24HMS_FMT VARCHAR2(30) := 'YYYY-MM-DD HH24:MI:SS';
    begin
        --
        DBMS_OUTPUT.PUT_LINE(P_QUERY);
        -- OPEN CURSOR
        L_THECURSOR := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE( L_THECURSOR, P_QUERY, DBMS_SQL.NATIVE );
        DBMS_SQL.DESCRIBE_COLUMNS( L_THECURSOR, L_COLCNT, L_DESCTBL );
        L_STATUS := DBMS_SQL.EXECUTE(L_THECURSOR);
        -- DUMP/DEFINE TABLE COLUMN NAME
        for I in 1 .. L_COLCNT loop
            DBMS_OUTPUT.PUT( L_SEPARATOR || '"' || L_DESCTBL(I).COL_NAME || '"' );
            -- https://docs.oracle.com/cd/A91202_01/901_doc/server.901/a90125/sql_elements2.htm#54201
            if L_DESCTBL(I).COL_TYPE = 2 then -- number
                DBMS_SQL.DEFINE_COLUMN( L_THECURSOR, I, L_COLUMNVALUE_NUMBER );
            elsif L_DESCTBL(I).COL_TYPE in (12, 180, 181) then  -- date, timestamp
                DBMS_SQL.DEFINE_COLUMN( L_THECURSOR, I, L_COLUMNVALUE_DATE );
            else      -- others, consider as varchar
                DBMS_SQL.DEFINE_COLUMN( L_THECURSOR, I, L_COLUMNVALUE_CHAR, 32767 );
            end if;
            L_SEPARATOR := ',';
        end loop;
        DBMS_OUTPUT.PUT_LINE('');
        -- DUMP TABLE COLUMN VALUE
        while ( DBMS_SQL.FETCH_ROWS(L_THECURSOR) > 0 ) loop
            R_COUNT := R_COUNT + 1;
            L_SEPARATOR := '';
            for I in 1 .. L_COLCNT loop
                if L_DESCTBL(I).COL_TYPE = 2 then -- number
                    DBMS_SQL.COLUMN_VALUE( L_THECURSOR, I, L_COLUMNVALUE_NUMBER );
                    DBMS_OUTPUT.PUT(L_SEPARATOR || L_COLUMNVALUE_NUMBER);
                elsif L_DESCTBL(I).COL_TYPE in (12, 180, 181) then  -- date, timestamp
                    DBMS_SQL.COLUMN_VALUE( L_THECURSOR, I, L_COLUMNVALUE_DATE );
                    DBMS_OUTPUT.PUT(L_SEPARATOR || '"' || to_char(L_COLUMNVALUE_DATE, DT_24HMS_FMT) || '"');
                else      -- others, consider as varchar
                    DBMS_SQL.COLUMN_VALUE( L_THECURSOR, I, L_COLUMNVALUE_CHAR );
                    DBMS_OUTPUT.PUT(L_SEPARATOR || '"' || trim(both ' ' from replace(L_COLUMNVALUE_CHAR,'"','""')) || '"');
                end if;
                L_SEPARATOR := ',';
            end loop;
            DBMS_OUTPUT.PUT_LINE('');
        end loop;
        --CLOSE CURSOR
        DBMS_SQL.CLOSE_CURSOR(L_THECURSOR);
        return R_COUNT;
    exception
        when others then
            DBMS_OUTPUT.PUT_LINE('Error code ' || SQLCODE || ': ' || SQLERRM);
            raise;
    end qry2csv;
begin 
    -- 
    v_sql := ' select * ' || chr(10) ||
             ' from ' || trim(:ash_tbl_name) || chr(10) ||
             ' where SAMPLE_TIME between to_timestamp(''' || trim(:sample_time_from) || ''', ''' || trim(:c_time_fmt) || ''')' || chr(10) ||
             '                       and to_timestamp(''' || trim(:sample_time_to) || ''', ''' || trim(:c_time_fmt) || ''')' || chr(10) ||
             ' order by ';
    if trim(:ash_tbl_name) = 'DBA_HIST_ACTIVE_SESS_HISTORY' THEN
        v_sql := v_sql || 'INSTANCE_NUMBER';
    else 
        v_sql := v_sql || 'INST_ID';
    end if;
    v_sql := v_sql || ', SAMPLE_ID';
    -- 
    :csv_record_count := qry2csv(v_sql);
end;
/
spool off

-- spool 
set term off echo off;
spool &&ash_csv_out_filename
declare
begin
    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('SAMPLE_TIME_FROM: ' || :sample_time_from);
    DBMS_OUTPUT.PUT_LINE('SAMPLE_TIME_TO  : ' || :sample_time_to);
    DBMS_OUTPUT.PUT_LINE('CURR_HOUR_TIME  : ' || :curr_hour_time);
    DBMS_OUTPUT.PUT_LINE('PREV_HOUR_TIME  : ' || :prev_hour_time);
    DBMS_OUTPUT.PUT_LINE('ASH_TBL_NAME    : ' || :ash_tbl_name);
    DBMS_OUTPUT.PUT_LINE('CSV_FILE_NAME   : ' || :ash_csv_file);
    DBMS_OUTPUT.PUT_LINE('CSV_RECORD_COUNT: ' || :csv_record_count);
    DBMS_OUTPUT.PUT_LINE('=============================================');
end;
/
spool off

-- #########################
-- post-process
-- 
set term on echo off;
declare
begin
    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('NONRACDIAG_OUTPUT : ' || :nonracdiag_out_file);
    DBMS_OUTPUT.PUT_LINE('HANG_ANALYZE      : ' || :hanganalyze_trc_file);
    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('SAMPLE_TIME_FROM  : ' || :sample_time_from);
    DBMS_OUTPUT.PUT_LINE('SAMPLE_TIME_TO    : ' || :sample_time_to);
    DBMS_OUTPUT.PUT_LINE('CURR_HOUR_TIME    : ' || :curr_hour_time);
    DBMS_OUTPUT.PUT_LINE('PREV_HOUR_TIME    : ' || :prev_hour_time);
    DBMS_OUTPUT.PUT_LINE('ASH_TBL_NAME      : ' || :ash_tbl_name);
    DBMS_OUTPUT.PUT_LINE('CSV_FILE_NAME     : ' || :ash_csv_file);
    DBMS_OUTPUT.PUT_LINE('CSV_RECORD_COUNT  : ' || :csv_record_count);
end;
/

-- 
-- ########################################
-- Compress output files into a zip file
-- ########################################
--
-- 1. nonracdiag_orcl1980_0926_0722.out <nonracdiag_&&dbname&&timestamp&&suffix>
-- 2. hanganalyze <SELECT VALUE FROM V$DIAG_INFO WHERE NAME = 'Default Trace File'>
-- 3. ash_csv_orcl1980_0926_0722.csv <nonracdiag_ash_csv_&&dbname&&timestamp..csv>
-- 4. ash_csv_orcl1980_0926_0722.csv.out <nonracdiag_ash_csv_&&dbname&&timestamp..csv..out>
--
set term on echo off;
Prompt 
Prompt =============================================
Prompt Moving diagnostic files to &&diag_zip_file
Prompt 

HOS zip -m &&diag_zip_file &&nonracdiag_out_file
HOS zip -jm &&diag_zip_file &&hanganalyze_trc_file
HOS zip -m &&diag_zip_file &&ash_csv_file
HOS zip -m &&diag_zip_file &&ash_csv_out_filename


-- reset
undefine sample_time_from sample_time_to
set pagesize 14 embedded off
set lines 80
set term on 
set feedback on
set trimspool off
set heading on
set colsep ' '

exit
