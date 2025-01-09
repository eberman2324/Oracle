REM **
REM ** Script: who_active.sql
REM ** Descr: Lists the "ACTIVE" sessions with some session-level statistics
REM **        sorted by username and sid.  Note:  qcsid stands for 
REM **        query-coordinator sid and is the sid of the "master" or 
REM **        coordinator for a parallel query.
REM **        
REM **
select /*+ leading(s) */ decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID, 
       s.sid, 
       p.spid, 
       substr(decode(s.type, 'USER', s.username, 'BACKGROUND', 'ORA-' ||bg.name, s.username), 1, 15) as username, 
       substr(decode(aa.name, 'UNKNOWN', '--', aa.name ), 1, 15) as command,
       s.status,
       substr(s.osuser, 1, 15) as osuser, 
       substr(s.machine, 1, 30) as machine,
       substr(s.program, 1, 20) as program, 
       substr(s.module, 1, 15) as module,
       substr(s.action, 1, 15) as action,
       s.sql_hash_value,
       sw.event,
       s.lockwait,
       s.row_wait_obj#,
       s.row_wait_row#,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time, 
       s.last_call_et,
       sio.block_gets,
       sio.consistent_gets,
       sio.physical_reads,
       sio.block_changes,
       sio.consistent_changes
from v$session s,
     v$process p,
     v$sess_io sio,
     v$px_session pxs,
     v$bgprocess bg,
     audit_actions aa,
     v$session_wait sw
where s.paddr = p.addr
  and s.sid = sio.sid
  and s.saddr = pxs.saddr (+)
  and s.command = aa.action
  and s.paddr = bg.paddr (+)
  and s.status = 'ACTIVE'
  and s.type <> 'BACKGROUND'
  and s.sid = sw.sid
order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid)
/
