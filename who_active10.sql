REM **
REM ** Script: who_active10.sql
REM ** Descr: Lists the "ACTIVE" sessions with some session-level statistics
REM **        sorted by username and sid.  Note:  qcsid stands for 
REM **        query-coordinator sid and is the sid of the "master" or 
REM **        coordinator for a parallel query.
REM **        
REM **
select /*+ leading(s) */ 
       decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID, 
       cast(s.sid||','||s.serial# as varchar2(13)) as sid_serial,
       s.blocking_session as blk_sess, 
       cast(p.spid as varchar2(10)) as spid, 
       cast(decode(s.type, 'USER', s.username, s.username) as varchar2(10)) as username, 
       cast(decode(aa.name, 'UNKNOWN', '--', aa.name ) as varchar2(10)) as command,
       s.status,
       cast(s.osuser as varchar2(15)) as osuser,
       s.last_call_et, 
       s.sql_id,
       s.prev_sql_id,
       cast(s.event as varchar2(30)) as event,
       cast(s.machine as varchar2(20)) as machine,
       cast(s.program as varchar2(20)) as program, 
       cast(s.module as varchar2(15)) as module,
       cast(s.action as varchar2(15)) as action,
       s.lockwait,
       s.row_wait_obj#,
       s.row_wait_row#,
       (select cast(o1.object_name as varchar2(20)) from dba_objects o1 where o1.object_id=s.PLSQL_ENTRY_OBJECT_ID) as PLS_Entry_OBJ,
       s.PLSQL_ENTRY_SUBPROGRAM_ID,
       (select cast(o1.object_name as varchar2(20)) from dba_objects o1 where o1.object_id=s.PLSQL_OBJECT_ID) as PLS_OBJ,
       s.PLSQL_SUBPROGRAM_ID,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time, 
       sio.block_gets,
       sio.consistent_gets,
       sio.physical_reads,
       sio.block_changes,
       sio.consistent_changes
from v$session s,
     v$process p,
     v$sess_io sio,
     v$px_session pxs,
     audit_actions aa
where s.paddr = p.addr
  and s.sid = sio.sid
  and s.saddr = pxs.saddr (+)
  and s.command = aa.action
  and s.status = 'ACTIVE'
  and s.type <> 'BACKGROUND'
  and s.event not in ('jobq slave wait', 'rdbms ipc message')
  and s.event not like 'Streams AQ:%'
order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid)
/
