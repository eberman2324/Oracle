
select
   s.sid,
   s.serial#,
   s.username,
   u.segment_name,
   count(u.extent_id) "Extent Count",
   t.used_ublk,
   t.used_urec,
   s.program
from
   v$session        s,
   v$transaction    t,
   dba_undo_extents u
where
   s.taddr = t.addr
and
   u.segment_name like '_SYSSMU'||t.xidusn||'_%$'
and
   u.status = 'ACTIVE'
group by
   s.sid,
   s.serial#,
   s.username,
   u.segment_name,
   t.used_ublk,
   t.used_urec,
   s.program
order by
   t.used_ublk desc,
   t.used_urec desc,
   s.sid,
   s.serial#,
   s.username,
   s.program

