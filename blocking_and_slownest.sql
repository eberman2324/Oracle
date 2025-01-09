
--************WHO IS ACTIVE and WAITS*******************************************
--*******************************************************************************


select count(*) from v$session where status = 'ACTIVE';
select count(*) from v$session;
--Normal select count(*) from v$session;
--1400 (01/11/2021)
--1700 (05/16/2021)
--2600 (05/17/2021)
--2650 (07/19/2021)
--2900 (01/06/2022)
--3400 10/12/2021  - with SupplierInquery spike
--3744  - 4352 01/10/22 - after Scalability additions for 2022
--4500 - (12/15/2022)
--6200 - 7304 - (12/19/2022) - after Dec Scalability additions for  2023
--8000 - 8400 - (12/19/2022) - after Feb Scalability additions for  2023


select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE  from v$session where SCHEMANAME = 'PROD_DW' GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC

select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE  from v$session GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC


select count(*) from v$session  where SCHEMANAME = 'S881492';
select  SID, SQL_ID, MACHINE, SCHEMANAME  from v$session where program like '%sqlplus%'
select  SID, SQL_ID, MACHINE, SCHEMANAME  from v$session where program like '%Beyond%'

select count(*) from v$session
where program='OMS'
and status = 'INACTIVE';



--1250- 1350 (01/11/2021)
--3800 (01/11/2022)

select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE  from v$session where SCHEMANAME = 'DBSNMP' GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC


select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE,SQL_ID from v$session where USERNAME ='DBSNMP' GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC


-- DW BOT
select  LAST_CALL_ET  from v$session where SQL_ID = '6nbjanj2amuct' 
select  *  from v$session where USERNAME IN ( 'S012553') and SQL_ID = '59bbwjwgwu8nf' 

select  *  from v$session where USERNAME IN ( 'S038217') 

--If the session status column is currently ACTIVE, then the value of last_call_et represents the elapsed time in seconds since the session has become active.
--  If the session status column is currently INACTIVE, then the value of last_call_et represents the elapsed time in seconds since the session has become inactive."
select  LAST_CALL_ET  from v$session where SID IN (7775) 



SELECT SID, SERIAL#, opname, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%COMPLETE"
FROM   V$SESSION_LONGOPS
WHERE
TOTALWORK != 0
AND    SOFAR != TOTALWORK
order by 1;

 select b.sid, b.username, b.osuser, used_ublk,used_urec,start_time
	from v$transaction a, v$session b
	where a.ses_addr = b.saddr and b.sid in (684) order by start_time ;
    
    select sid,blocking_session,event,last_call_et,logon_time,lockwait from v$session
where lockwait is not null order by logon_time

  select sid,blocking_session from v$session where lockwait is not null;
  
  
  --test first
   select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s, v$lock l where s.blocking_session=l.sid and l.block<>0;
   select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s where  
   s.sid IN (143,155);

SELECT a.SQL_ID
FROM v$sqlarea a, v$session b
WHERE a.SQL_ID = b.SQL_ID and b.last_call_et>500;
and   a.SQL_TEXT LIKE '%ClaimWorkbasket%';



select address, hash_value, executions, loads, version_count, invalidations, parse_calls,sql_plan_baseline
from v$sqlarea 
where sql_id = '4q5qf56zmwzyp';

select COUNT(*) from v$session where sql_id='6dpsx1119j0bb';

select COUNT(*) from v$session where sql_id='c09csgz4vum2g';

-- lat_call_et > 500 sec means 8 Min
select COUNT(*) from v$session where sql_id='965by918vgvqu'  and last_call_et>300;
select COUNT(*) from v$session where sql_id='aqnwqj9w27dk3'  and last_call_et>300;

select * from v$session where sql_id='0xd3h2j7j3hfm';

3ccgxp7vqv3vy
select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id='atd5pjamxss0p'; 

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id='3ccgxp7vqv3vy' and last_call_et>300;


select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where event='library cache pin';

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where program like '%Beyond%'

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where program like '%rman%'



select count(*) from  v$session where event='library cache pin';

select *  from v$session where sql_id='7jhsphvgfmpdc'

select *  from v$session where username = 'SYS' and program like '%sqlplus%'

select  SID  from v$session where username = 'SYS' and program like '%sqlplus%'

select IS_BIND_SENSITIVE  from v$sqlarea where SQL_ID = '4qhyj47pmm58u'





select b.sid, b.username, b.osuser, used_ublk,used_urec,start_time
          from v$transaction a, v$session b
          where a.ses_addr = b.saddr and b.sid in (684) order by start_time ;
          
          
          
          
select /*+ leading(s) */ decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID, 
       s.sid, 
       p.spid, 
       substr(decode(s.type, 'USER', s.username, 'BACKGROUND', 'ORA-' ||bg.name, s.username), 1, 15) as username, 
       substr(decode(aa.name, 'UNKNOWN', '--', aa.name ), 1, 15) as command,
       s.status,
       s.last_call_et,
       substr(s.osuser, 1, 15) as osuser, 
       substr(s.machine, 1, 30) as machine,
       substr(s.program, 1, 20) as program, 
       substr(s.action, 1, 15) as action,
       s.sql_hash_value,
       s.sql_id,
       sw.event,
       s.lockwait,
       s.row_wait_obj#,
       s.row_wait_row#,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time, 
       sio.block_gets,
       sio.consistent_gets,
       sio.physical_reads,
       sio.block_changes,
       sio.consistent_changes,
       s.prev_sql_id,
       s.prev_hash_value
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
order by last_call_et desc,s.sql_id,sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid);


SELECT OWNER, INDEX_NAME, STATUS FROM DBA_INDEXES WHERE STATUS LIKE 'UN%';

 select address, hash_value, executions, loads, version_count, invalidations, parse_calls,sql_plan_baseline
from v$sqlarea 
where sql_id = '4k6j3xhkm19b5';

select * from dba_sql_profiles where name  = 'SYS_SQLPROF_016d5ef876840005'

--************BLOCKING LOCKS****************************************************
--*******************************************************************************

-- SID is the vicktm
--Blcoking_session is bad guy
    select sid,blocking_session,event,last_call_et,logon_time,lockwait from v$session
where lockwait is not null;

  select sid,blocking_session from v$session where lockwait is not null;


select count(*) from v$session
where lockwait is not null;

select * from v$session ;

select * from v$session where sql_id is null;

select username, count(*) from v$session group by username;

select sql_id, count(*) as CNT from v$session group by sql_id order by CNT DESC ;

select sid,blocking_session,event,last_call_et,logon_time,lockwait from v$session
where lockwait is not null;

select * from dba_dml_locks;

select count(*) from dba_dml_locks;

--- !!! Look for  any that are waiting on  "SQL*Net message from client" also check last_call_et in sec/60 = min
select decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID,
        s.sid, s.serial#,
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
        s.prev_hash_value,
        sw.event,
        s.lockwait,
        s.row_wait_obj#,
        s.row_wait_row#,
        to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time,
        s.last_call_et
 from v$session s,
      v$process p,
      v$sess_io sio,
      v$px_session pxs,
      v$bgprocess bg,
      audit_actions aa,
      v$session_wait sw,
      v$transaction t
 where s.paddr = p.addr
   and s.sid = sio.sid
   and s.saddr = pxs.saddr (+)
   and s.command = aa.action
   and s.paddr = bg.paddr (+)
   and s.saddr = t.ses_addr
   and to_date(t.start_time, 'MM/DD/YY HH24:MI:SS') < sysdate - 1/1440
   and s.sid = sw.sid
 order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid)
 

 --- Create special kill session sql for real blockers
 select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s where  
 s.sid = 23405;
 alter system kill session '12277,50921';

 select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s where  
 s.sid IN (143,155);
 
 
 select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s, v$lock l where s.blocking_session=l.sid and l.block<>0;
 
 
-- Or 
--1. Login to aetnaprod
--2. cd /workability/home/oracle/Monitor/Sql
--3. sqlplus / as sysdba
--4. spool kill.sql
--5.  select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session s where  
      --s.sid = 1516;
      
--6. spool off;
--7. @kill.sql




select * from v$session where status = 'KILLED' 




---How to check historical (at least today - 1) blocking locks----
SELECT distinct
       a.sql_id ,
        a.session_id,
        a.blocking_session blocker_ses,
       a.blocking_session_serial# blocker_ser,
       a.sample_time,
            s.sql_text,
       a.module
FROM  V$ACTIVE_SESSION_HISTORY a,
      v$sql s
where a.sql_id=s.sql_id
  and blocking_session is not null
  and a.user_id <> 0 --  exclude SYS user
  and a.sample_time > sysdate - 1
  order by a.sample_time 
  
  SELECT distinct
       a.sql_id ,
        a.session_id,
        a.blocking_session blocker_ses,
       a.blocking_session_serial# blocker_ser,
       a.sample_time,
            s.sql_text,
       a.module
FROM  V$ACTIVE_SESSION_HISTORY a,
      v$sql s
where a.sql_id=s.sql_id
  and blocking_session is not null
  and a.user_id <> 0 --  exclude SYS user
  and a.sample_time   BETWEEN
 to_date ('2023-07-10T20:00:00', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND
   to_date ('2023-07-10T23:00:00', 'YYYY-MM-DD"T"HH24:MI:SS')
  order by a.sample_time 
  
  
  
SELECT distinct
       a.sql_id ,
        a.session_id,
        a.blocking_session blocker_ses,
       a.blocking_session_serial# blocker_ser,
       a.sample_time,
            s.sql_text,
       a.module
FROM  V$ACTIVE_SESSION_HISTORY a,
      v$sql s
where a.sql_id=s.sql_id and
    a.sql_id = '33702pbcngtvb'
    

--************ LONGOPS *******************************************
--****************************************************************

Select * from V$SESSION_LONGOPS  where sid = 1009  order by start_time desc
Select * from V$SESSION_LONGOPS  where sid IN ('2342') order by start_time desc
Select * from V$SESSION_LONGOPS  where sql_id = '8yb8jwguc9hh3'  order by start_time desc
Select * from V$SESSION_LONGOPS   order by start_time desc

select *  from v$mvrefresh;


select b.sid, b.username, b.osuser, used_ublk,used_urec,start_time
	from v$transaction a, v$session b
	where a.ses_addr = b.saddr and b.sid in (306) order by start_time ;
 

SELECT   A.tablespace_name tablespace, D.mb_total,
         SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
         D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM     v$sort_segment A,
         (
         SELECT   B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
         FROM     v$tablespace B, v$tempfile C
         WHERE    B.ts#= C.ts#
         GROUP BY B.name, C.block_size
         ) D
WHERE    A.tablespace_name = D.name
GROUP by A.tablespace_name, D.mb_total;

SELECT SID, SERIAL#, opname, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%COMPLETE",MESSAGE
FROM   V$SESSION_LONGOPS
WHERE
TOTALWORK != 0
AND    SOFAR != TOTALWORK
order by 1;

select count(*) as LOGS_GENERATED, to_char(next_time,'mm/dd/yyyy HH24') AS HOUR, SUM(BLOCKS * BLOCK_SIZE) /1024/1024/1024 SIZE_GB
from v$archived_log where to_char(next_time,'mm/dd/yyyy') = '06/03/2021'
group by to_char(next_time,'mm/dd/yyyy HH24')
ORDER BY HOUR;



SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'Gather%'
    AND TOTALWORK != 0
  AND SOFAR  != TOTALWORK
;




select a.sql_text from v$sqltext a,v$session b WHERE  b.program like '%sqlplus%'
AND a.address = b.sql_address
AND    a.hash_value = b.sql_hash_value
and last_call_et > 100;



SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE",sysdate + TIME_REMAINING/3600/24 end_time,MESSAGE
FROM V$SESSION_LONGOPS
WHERE MESSAGE LIKE '%SUPPLIER%'
    AND TOTALWORK != 0
  AND SOFAR  != TOTALWORK
;


select extension_name, extension from   dba_stat_extensions where  table_name = 'CLAIM_PAYABLE';

select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time, MESSAGE
from   v$session_longops
where  
     TOTALWORK != 0
  AND SOFAR  != TOTALWORK and SID IN (
'4644',
'690',
'422',
'6954',
'7110',
'7375',
'58',
'214',
'6695',
'2364',
'1469',
'1100',
'1938',
'1281',
'1687',
'2093',
'893'
   )
;




select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time
from   v$session_longops
where  totalwork > sofar
and    opname  LIKE '%aggregate%'
and    opname like 'RMAN%';


--End time
select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time
from   v$session_longops
where  totalwork > sofar
--and    opname NOT LIKE '%aggregate%'
and    opname like 'RMAN%'; 


select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time, MESSAGE
from   v$session_longops
where  
     TOTALWORK != 0
  AND SOFAR  != TOTALWORK and SID IN ('2342')
;

select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time, MESSAGE
from   v$session_longops
where  
     TOTALWORK != 0
  AND SOFAR  != TOTALWORK
;




SELECT DISTINCT owner, segment_name, segment_type,dbc.BLOCK#,dbc.BLOCKS FROM   v$database_block_corruption dbc JOIN dba_extents e ON dbc.file# = e.file_id AND dbc.block# BETWEEN e.block_id and e.block_id+e.blocks-1 ORDER BY 1,2;
SELECT DISTINCT owner, segment_name, segment_type  FROM   v$database_block_corruption dbc JOIN dba_extents e ON dbc.file# = e.file_id AND dbc.block# BETWEEN e.block_id and e.block_id+e.blocks-1 ORDER BY 1,2;


select * from v$database_block_corruption 

select owner,table_name, to_char(last_analyzed,'DD-MON-YYYY HH24:MI:SS') from dba_tables where owner='PROD' AND TABLE_NAME IN
( 'CVC_STEP')  

select index_name, last_analyzed from dba_indexes where table_name = 'CVC_STEP'

select table_name, last_analyzed from dba_tables where table_name = 'CVC_STEP'

select * from dba_optstat_operations where operation = 'gather_table_stats' and target like '%CVC_STEP%'


select table_name, table_size from dba_segments ,PROD.WORKTABLE where segment_name = table_name and tablespace_name IN ('DATA') order by 2 desc

SELECT tablespace_name, segment_type, owner, segment_name
 FROM dba_extents
 WHERE file_id = 881
 and 907055209 between block_id AND block_id + blocks - 1;
 
 

select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
--and   i.table_name   IN 
--(
--'TRANSACTION_STEP_FACT'
--)
--and s.tablespace_name <> 'PROD_INDEX' 
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD'
order by 3 desc;

-- Index size
select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
and    i.index_name   IN 
(
'TRANSACTION_STEP_FACT_ID2'

)
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD_DW'
order by 3 desc;

-- Table and Indexes size
select segment_name Name, segment_type Type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s
where s.segment_name IN (
'AUDIT_LOG_ENTRY'
)
and   s.segment_type = 'TABLE'
and   s.owner        = 'PROD'
union all
select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
and   i.table_name   IN (
'AUDIT_LOG_ENTRY'
)
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD'
order by 3 desc;

-- Partition table size
select segment_name, partition_name,bytes/power(1024,2) sizeMB from dba_segments where segment_name = 'CAPITATION_SUMMARY';

SELECT OWNER, TABLE_NAME, STATTYPE_LOCKED FROM DBA_TAB_STATISTICS 
WHERE STATTYPE_LOCKED IS NOT NULL and table_name = 'MEMBERSHIP' ;


SELECT OWNER, TABLE_NAME, STATTYPE_LOCKED FROM DBA_TAB_STATISTICS 
WHERE STATTYPE_LOCKED IS NOT NULL AND OWNER = 'PROD' ORDER BY 2;


select 'ALTER INDEX ' || '' ||  ' PROD.' || index_name || ' REBUILD  PARALLEL 16 TABLESPACE INDX6' ||';' from dba_indexes where table_name = 'PREMIUM_PAYMENT_ROSTER_ENTRY' and owner = 'PROD'
select 'ALTER INDEX ' || '' ||  ' PROD.' || index_name || ' NOPARALLEL' ||';' from dba_indexes where table_name = 'PREMIUM_PAYMENT_ROSTER_ENTRY' and owner = 'PROD'

select 'ALTER INDEX ' || '' ||  ' PROD_DW.' || index_name || ' NOPARALLEL' ||';' from dba_indexes where index_name like '%AEDBA%' and owner = 'PROD_DW'


select * from dba_indexes


select table_name from dba_segments ,PROD.WORKTABLE where segment_name = table_name and  tablespace_name IN ('DATA4') and segment_type = 'TABLE';



SELECT SUM(bytes)/1024/1024/1024 gb
  FROM dba_segments
 WHERE (owner ='PROD' and
       segment_name IN 
 (
'ATTACHMENT'
)
) 
    OR (owner, segment_name) IN (
        SELECT owner, segment_name
          FROM dba_lobs
         WHERE owner = 'PROD'
            AND table_name IN 
(
'ATTACHMENT'
)
 )
 
select *  from dba_segments where   tablespace_name IN ('DATA4')  and SEGMENT_TYPE = 'TABLE';

select segment_name Name, segment_type Type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s
where s.segment_name IN (
'BACK_FEED_PAYMENT_STATUS'
)
and   s.segment_type = 'TABLE'
and   s.owner        = 'PROD'
union all
select segment_name, segment_type, s.bytes/1024/1024/1024 GB, s.tablespace_name TS
from dba_segments s,
     dba_indexes i
where s.segment_name = i.index_name
and   s.owner        = i.owner
and   i.table_name   IN (
'BACK_FEED_PAYMENT_STATUS'
)
and   s.segment_type = 'INDEX'
and   s.owner        = 'PROD'
order by 3 desc;





select SUM(bytes)/1024/1024/1024 gb  from dba_segments where   tablespace_name IN ('DATA4') and  SEGMENT_TYPE = 'TABLE';
5TB
select SUM(bytes)/1024/1024/1024 gb  from dba_segments where   tablespace_name IN ('DATA4') and  SEGMENT_TYPE = 'LOBSEGMENT';
13.1 TB
select SUM(bytes)/1024/1024/1024 gb  from dba_segments where   tablespace_name IN ('DATA4') and  SEGMENT_TYPE = 'LOBINDEX';
01
select SUM(bytes)/1024/1024/1024 gb  from dba_segments where   tablespace_name IN ('DATA4') and  SEGMENT_TYPE = 'LOBSEGMENT' and segment_name = 'SYS_LOB0000295690C00002$$'

select SUM(bytes)/1024/1024/1024 gb  from dba_segments where   tablespace_name IN ('INDX2','INDX3','INDX4','INDX5') and  SEGMENT_TYPE = 'INDEX';

select sum(bytes)/1024/1024/1024 gb from dba_data_files    where TABLESPACE_NAME IN ('INDX2','INDX3','INDX4','INDX5') 

 select 'alter system kill session ''' || s.sid || ',' || s.serial# || ''';' from v$session_longops s 
 where  s.totalwork > s.sofar
and    s.opname NOT LIKE '%aggregate%'
and    s.opname like 'RMAN%';


select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time
from   v$session_longops
where  
 SID IN ('42','1086','1102','3724')




--************ TEMP tablespace *************************************
--****************************************************************

-- Total TEMP free now
SELECT   A.tablespace_name tablespace, D.mb_total,
         SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
         D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM     v$sort_segment A,
         (
         SELECT   B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
         FROM     v$tablespace B, v$tempfile C
         WHERE    B.ts#= C.ts#
         GROUP BY B.name, C.block_size
         ) D
WHERE    A.tablespace_name = D.name
GROUP by A.tablespace_name, D.mb_total;


SELECT   A.tablespace_name tablespace, D.mb_total,
         SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
         D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM     v$sort_segment A,
         (
         SELECT   B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
         FROM     v$tablespace B, v$tempfile C
         WHERE    B.ts#= C.ts# and b.name = 'TEMP'
         GROUP BY B.name, C.block_size
         ) D
WHERE    A.tablespace_name = D.name and A.tablespace_name = 'TEMP'
GROUP by A.tablespace_name, D.mb_total;

select sum(used_blocks/1024/1024/1024) from gv$sort_segment where tablespace_name = 'TEMP';


SELECT trim(count(*)) FROM v$session a, v\$tempseg_usage b, v\$sqlarea c
WHERE a.saddr = b.session_addr AND
c.address= a.sql_address AND
(b.blocks*8)/(1024*1024) >= 400 AND
c.hash_value = a.sql_hash_value;



-- Historical TEMP usage

select sql_id,username, program,max(TEMP_SPACE_ALLOCATED)/(1024*1024*1024) gig 
from DBA_HIST_ACTIVE_SESS_HISTORY,DBA_USERS 
where DBA_HIST_ACTIVE_SESS_HISTORY.user_id = DBA_USERS.user_id and
sample_time
 BETWEEN
 to_date ('2024-10-14T12:00:00', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND
  to_date ('2024-10-14T14:00:59', 'YYYY-MM-DD"T"HH24:MI:SS')
  --and sql_id = '6vnhyd4fstzhs'
 and TEMP_SPACE_ALLOCATED > (20*1024*1024*1024) 
group by sql_id,username,program order by gig desc;

select sql_id,username, program,max(TEMP_SPACE_ALLOCATED)/(1024*1024*1024) gig 
from DBA_HIST_ACTIVE_SESS_HISTORY,DBA_USERS 
where DBA_HIST_ACTIVE_SESS_HISTORY.user_id = DBA_USERS.user_id 
 and sql_id = '63u9gmyyw14x8'
 --and TEMP_SPACE_ALLOCATED > (20*1024*1024*1024) 
group by sql_id,username,program order by gig desc;


-- Who is using TEMP space now

SELECT   S.sid || ',' || S.serial# sid_serial, S.username, S.osuser, P.spid, S.module,
 P.program, SUM (T.blocks) * TBS.block_size / 1024 / 1024 mb_used, T.tablespace,
 COUNT(*) statements
 FROM     v$sort_usage T, v$session S, dba_tablespaces TBS, v$process P
 WHERE    T.session_addr = S.saddr
 AND      S.paddr = P.addr
 AND      T.tablespace = TBS.tablespace_name
 GROUP BY S.sid, S.serial#, S.username, S.osuser, P.spid, S.module,
 P.program, TBS.block_size, T.tablespace
 ORDER BY mb_used desc;
 
 SELECT   S.sid || ',' || S.serial# sid_serial, S.username, S.osuser, P.spid, S.module,
 P.program, SUM (T.blocks) * TBS.block_size / 1024 / 1024 mb_used, T.tablespace,
 COUNT(*) statements
 FROM     v$sort_usage T, v$session S, dba_tablespaces TBS, v$process P
 WHERE    T.session_addr = S.saddr
 AND      S.paddr = P.addr
 AND      T.tablespace = TBS.tablespace_name and S.module like '%sqlplus%'
 GROUP BY S.sid, S.serial#, S.username, S.osuser, P.spid, S.module,
 P.program, TBS.block_size, T.tablespace
 ORDER BY mb_used desc;
 
 
 select   a.username, 
           a.sid,
           b.tablespace,
           sum((b.blocks*8)/(1024*1024)) as GBytes
from v$session a, v$tempseg_usage b
where a.saddr = b.session_addr
group by a.username,a.sid,b.tablespace
order by 4 desc; 

SELECT b.tablespace,
       ROUND(((b.blocks*p.value)/1024/1024),2)||'M' AS temp_size,
       a.inst_id as Instance,
       a.sid||','||a.serial# AS sid_serial,
       NVL(a.username, '(oracle)') AS username,
       a.program,
       a.status,
       a.sql_id
FROM   gv$session a,
       gv$sort_usage b,
       gv$parameter p
WHERE  p.name  = 'db_block_size'
AND    a.saddr = b.session_addr
AND    a.inst_id=b.inst_id
AND    a.inst_id=p.inst_id
ORDER BY b.tablespace, b.blocks
/

 
 SELECT  S.sid || ',' || S.serial# sid_serial, S.username, Q.hash_value, Q.sql_text,
 T.blocks * TBS.block_size / 1024 / 1024 mb_used, T.tablespace
 FROM    v$sort_usage T, v$session S, v$sqlarea Q, dba_tablespaces TBS
 WHERE   T.session_addr = S.saddr
 AND     T.sqladdr = Q.address
 AND     T.tablespace = TBS.tablespace_name
 ORDER BY mb_used desc;
 
 select sql_id,username, program,max(TEMP_SPACE_ALLOCATED)/(1024*1024*1024) gig 
from DBA_HIST_ACTIVE_SESS_HISTORY,DBA_USERS 
where DBA_HIST_ACTIVE_SESS_HISTORY.user_id = DBA_USERS.user_id and
sql_id = '6vnhyd4fstzhs'
group by sql_id,username,program order by sql_id;

SELECT trim(count(*)) FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr AND
c.address= a.sql_address AND
(b.blocks*8)/(1024*1024) >= 100 AND
c.hash_value = a.sql_hash_value;

SELECT d.EMAIL_ADDRESS,a.SQL_ID,(b.blocks*8)/(1024*1024)  FROM v$session a, v$tempseg_usage b, v$sqlarea c, aedba.strong_users d
WHERE a.saddr = b.session_addr AND
c.address= a.sql_address AND
(b.blocks*8)/(1024*1024) >= 20 AND
regexp_like(a.USERNAME, '[A|N][0-9]{6}.*') AND
a.SCHEMANAME= d.USERNAME AND
c.hash_value = a.sql_hash_value;


select USERNAME from dba_users where regexp_like(USERNAME, '[A|N][0-9]{6}.*')

select 'alter system kill session ''' || a.sid ||  ',' ||a.serial#|| ''' ;' FROM v$session a, v$tempseg_usage b, v$sqlarea c WHERE a.saddr = b.session_addr AND c.address= a.sql_address and (b.blocks*8)/(1024*1024) >= 2 AND regexp_like(a.USERNAME, '[A|N][0-9]{6}.*') AND c.hash_value = a.sql_hash_value ORDER BY  b.blocks desc;


 
 --************ UNDO *************************************
--********************************************************

 select BEGIN_TIME,EXPSTEALCNT as UP_IS_BAD,EXPBLKRELCNT as UP_IS_GOOD,
TUNED_UNDORETENTION, UNXPSTEALCNT as ZERO_IS_GOOD  FROM v$undostat

select tablespace_name,status,count(*)
from dba_undo_extents
group by tablespace_name,status;

 
  --************ SESSION*************************************
--********************************************************

--HEDWPROD
--Avg 600  - Sep2017

--HEPYPRD
--Avg 50 - Sep2017
--Avg 560 Oct2017


select count(*) from v$session;

select * from v$session where status = 'KILLED' 

--Current 
select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE  from v$session GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC

select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE  from v$session where user = 'PROD' GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC


select  *  from v$session where program like '%rman%' 

select machine,program, schemaname, Logon_time from  v$session where machine  like '%spnode45%' order by Logon_time desc

select *  from v$session where SID = 9

select *  from GV$session where SID = 1831

--Historical
select  COUNT(MODULE) AS SESSION_COUNT,MODULE from DBA_HIST_SQLSTAT  GROUP BY MODULE
ORDER BY SESSION_COUNT DESC

select  COUNT(MODULE) AS SESSION_COUNT,MODULE from DBA_HIST_SQLSTAT where module in ('tabprotosrv.exe')

select  COUNT(MODULE) AS SESSION_COUNT,MODULE from DBA_HIST_SQLSTAT where SQL_ID in ('b5fyygr7ytgyj')
GROUP BY MODULE
ORDER BY SESSION_COUNT DESC



select  *  from DBA_HIST_SQLSTAT where SQL_ID in ('fn3ux8hu6qg9b') ORDER BY SNAP_ID desc


--Find Snap ID 
SELECT HIST_SNAPSHOT.snap_id,
       HIST_SNAPSHOT.begin_interval_time,
       HIST_RESOURCE_LIMIT.current_utilization,    
       HIST_RESOURCE_LIMIT.max_utilization,
       HIST_RESOURCE_LIMIT.initial_allocation
 FROM DBA_HIST_RESOURCE_LIMIT HIST_RESOURCE_LIMIT, 
      SYS.DBA_HIST_SNAPSHOT   HIST_SNAPSHOT
WHERE HIST_RESOURCE_LIMIT.resource_name='processes'
  AND HIST_RESOURCE_LIMIT.snap_id=HIST_SNAPSHOT.snap_id
ORDER BY HIST_SNAPSHOT.snap_id DESC;

SELECT parsing_schema_name,COUNT(*) 
FROM DBA_HIST_SQLSTAT 
WHERE snap_id=194937
GROUP BY parsing_schema_name; 


SELECT SQL_ID,COUNT(*) 
FROM DBA_HIST_SQLSTAT 
WHERE snap_id=194937 
GROUP BY SQL_ID; 


SELECT MODULE,COUNT(*) 
FROM DBA_HIST_SQLSTAT 
WHERE snap_id=194937
GROUP BY MODULE; 


SELECT COUNT(*) 
FROM DBA_HIST_SQLSTAT 
WHERE snap_id=194937 




SELECT *
  FROM v$resource_limit
 WHERE resource_name='processes';
 
--Historical
 SELECT
         TRUNC(TIMESTAMP, 'HH24') HOUR
          ,A.USERNAME
          ,A.USERHOST
          ,COUNT(*)
    FROM SYS.DBA_AUDIT_TRAIL A
    WHERE A.ACTION_NAME = 'LOGON' and TO_CHAR(TIMESTAMP,'MM-DD-YYYY') = '01-04-2022' 
    --and a.username in ('PROD_DW')
    --and a.userhost = 'xhepyacm1p.aetna.com'
    GROUP BY A.USERNAME, A.USERHOST
            ,TRUNC(TIMESTAMP, 'HH24')
   ORDER BY 1, 2 

   
   SELECT *   FROM DBA_AUDIT_TRAIL WHERE
TO_CHAR(TIMESTAMP,'MM-DD-YYYY') = '01-23-2020'  order by 
TIMESTAMP desc;


   

  select * from V$ACTIVE_SESSION_HISTORY
where   SAMPLE_TIME >=TO_DATE('01/28/2023 08', 'MM/DD/YYYY HH24') 
and   SAMPLE_TIME < TO_DATE('01/28/2023 09', 'MM/DD/YYYY HH24') 
   
     
  select MIN(SAMPLE_TIME ) from V$ACTIVE_SESSION_HISTORY where  
       sample_time > sysdate - 1
   
                            

select  COUNT(MACHINE) AS SESSION_COUNT,MACHINE from V$ACTIVE_SESSION_HISTORY 
where  to_char(sample_time,'mm/dd/yyyy HH:MI' ) = '01/28/2023 08:10'  GROUP BY MACHINE
ORDER BY SESSION_COUNT DESC

select sql_id, count(*) from dba_hist_active_sess_history where 
sample_time
BETWEEN
        to_date ('2023-01-28T00:01:00', 'YYYY-MM-DD"T"HH24:MI:SS')
           AND
             to_date ('2023-01-28T23:59:00', 'YYYY-MM-DD"T"HH24:MI:SS')
             and SQL_ID = 'b5fyygr7ytgyj'
             group by sql_id order by 1
             
             select *  from dba_hist_active_sess_history where 
sample_time
BETWEEN
      to_date ('2023-01-28T00:01:00', 'YYYY-MM-DD"T"HH24:MI:SS')
           AND
             to_date ('2023-01-28T23:59:00', 'YYYY-MM-DD"T"HH24:MI:SS')
             and SQL_ID = 'b5fyygr7ytgyj'
             group by sql_id order by 1
             
             
             
SELECT USERHOST, count(*)  FROM DBA_AUDIT_TRAIL WHERE TIMESTAMP
BETWEEN
      to_date ('2022-01-30T02:00:00', 'YYYY-MM-DD"T"HH24:MI:SS')
           AND
             to_date ('2022-01-30T05:00:00', 'YYYY-MM-DD"T"HH24:MI:SS')
              --and USERNAME IN ('PROD') 
               Group by USERHOST

-- HISTORY of execution for particular SQL_ID
select instance_number inst_id,SESSION_ID,USER_ID,PROGRAM,sql_id,SQL_CHILD_NUMBER,sql_plan_hash_value,sql_exec_start  from
dba_hist_active_sess_history where
sql_id='b9r3yf6pknbkx'
order by sql_exec_start
--Session id: 10101
--sql_exec_start: 2/1/2023 12:35:18 AM

-- To find Sql Hanging or not
select sess_io.inst_id,
sess_io.sid,
sesion.sql_id,
sess_io.block_gets,
sess_io.consistent_gets,
sess_io.physical_reads,
sess_io.block_changes,
sess_io.consistent_changes
from gv$sess_io sess_io, gv$session sesion
where sesion.sid = sess_io.sid and
sess_io.inst_id = sesion.inst_id and
sesion.sql_id='b5fyygr7ytgyj'
and sesion.username is not null ;

 
-- *****************LONG TRANSACTIONS ****************************************
-- ***************************************************************************

-- When we need to kill push_to_datarep session.
   -- kill on wkabprod side
   -- see if needed to be killed on dr02
   -- Also kill OS session
   -- Watch and monitor select * from V$FAST_START_TRANSACTIONS

select start_time,used_ublk,used_urec from v$transaction order by start_time desc
select *  from v$transaction order by start_time desc
select *  from v$transaction where status = 'ACTIVE'
select sum(used_ublk) from v$transaction;

--Monitor rollback after shutdown (See note: 265198.1 and 375935.1)
select * from V$FAST_START_TRANSACTIONS
select * from v$fast_start_servers
select * from x$ktuxe where ktuxecfl = 'DEAD' and ktuxesta = 'ACTIVE'





select * from  V$SESSION_LONGOPS where OPNAME = 'Transaction Rollback' ;
select  * from V$SESSION_LONGOPS where target = 'LX_DAILY.WKAB_OVERPAY_MV' order by start_time desc


  SELECT a.sid, a.username,a.sql_hash_value, b.xidusn, b.used_urec, b.used_ublk,b.ubablk
  FROM v$session a, v$transaction b
  WHERE a.saddr = b.ses_addr and a.lockwait is not null;
  
  select b.sid, b.username, b.osuser, used_ublk,used_urec, start_time
	from v$transaction a, v$session b
	where a.ses_addr = b.saddr;
    
      select b.sid, b.username, b.osuser, used_ublk,used_urec,start_time
	from v$transaction a, v$session b
	where a.ses_addr = b.saddr and b.sid in (8620) order by start_time ;
    
    --RAC
    select b.sid, b.username, b.osuser, used_ublk,used_urec,start_time
	from gv$transaction a, Gv$session b
	where a.ses_addr = b.saddr and b.sid = 1831;
    
   
 
    --select rows_processed from v$sqlarea WHERE SQL_ID = 'a7t3hxt3zr7bx';
    
    
  
  --HOLDING SESSION sid
select * from dba_waiters; 
select distinct(holding_session) from dba_waiters;
select * from dba_blockers;
select * from DBA_DML_LOCKS; 
select session_id,name, mode_held from DBA_DML_LOCKS where session_id = 2226

select * from v$lock where block = 1

select * from v$transaction
select sum(used_ublk) from v$transaction;

select * from v$transaction
--UBABLK field if going down this mean rollback 
--             if going up this mean insert or update or delete going ok
             
             
select * from v$lock; --block column  = 1 lock that's blocking another session


---***************************************LATCH CONTENTION****************************************
--************************************************************************************************
select * 
from v$session s where s.last_call_et > 600 and sid 
in (select sid from v$session_wait where event='latch free');

select *  from v$session_wait where event='latch free';
--If latch free look at columns below
--P2TEXT
   number
--PT
   98
select * from v$latch where latch# = 20
--cache buffers chains
  --means that this session still running
   --Monitor via 

select * from v$sess_io where sid = 825

select sess_io.sid,
       sess_io.block_gets,
       sess_io.consistent_gets,
       sess_io.physical_reads,
       sess_io.block_changes,
       sess_io.consistent_changes
  from v$sess_io sess_io, v$session sesion
 where sesion.sid = sess_io.sid
   and sesion.sid IN (187);
--if consistent_gets increasing then this proofs that is still running
-- or look at mike's query below which has this column/view in it


select * from v$latch;
select *  from v$session_wait where event='latch free'; --if records this mean we have contention
select * from V$LATCH_MISSES

---###Here's what I did to clear out the old sessions 
--##that were spinning on latches on causing the CPU to max out.

select 'alter system kill session ''' || sid || ',' || serial# || ''';' last_call_et 
from v$session s where s.last_call_et > 600 and sid 
in (select sid from v$session_wait where event='latch free');


--
TO KILL PILE UP SESSIONS with latch contention

--1. Login to aetnaprod
--2. cd /workability/home/oracle/Monitor/Sql
--3. rm -f  kill_Latches.sql
--4. sqlplus / as sysdba
--5. @latch_locks.sql


select * from v$session where status= 'KILLED'

select * from v$session where sid = 774

select SID, USERNAME, machine,status from v$session where sid  
in (select sid from v$session_wait where event='latch free');


---***************************************SQL PROFILES and SQL PLAN BASELINES Search ****************************************
--************************************************************************************************
 ----sql profiles and sql plan baselines
 select * from dba_sql_profiles order by created   

   select * from dba_sql_plan_baselines order by created desc 
   
   select plan_hash_value from v$sql where sql_id = '4q5qf56zmwzyp' and plan_hash_value = '606883873';
   
    select SQL_HASH_VALUE from v$session where sql_id = '4q5qf56zmwzyp'
   
   select address, hash_value, executions, loads, version_count, invalidations, parse_calls,sql_plan_baseline
from v$sqlarea 
where sql_id = '4q5qf56zmwzyp';
select * from dba_sql_profiles

select
a.name,
a.status,
a.CREATED,
a.LAST_MODIFIED,
a.CATEGORY,
b.sql_id
from
DBA_SQL_PROFILES a,
(select distinct sql_id,sql_profile from (select sql_id,sql_profile from DBA_HIST_SQLSTAT where sql_id ='6ssjuq5xggkgz'
union
select sql_id,sql_profile from v$sql where sql_id ='6ssjuq5xggkgz')) b
where a.name=b.sql_profile;

select distinct 
   p.name      profile_name,
   s.sql_id    sql_id,
   p.created   created
from 
   dba_sql_profiles p,
   dba_hist_sqlstat s
where
   p.name=s.sql_profile
   order by created;

select sql_id,sql_profile from dba_hist_sqlstat where sql_profile is not null



---***************************************How to find out what Package or Store procedure is executing QUERY **************
--************************************************************************************************


select PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID, PLSQL_OBJECT_ID, PLSQL_SUBPROGRAM_ID
from v$session where SID = 53
--220507
select * from dba_objects where owner = 'LUMINX' and object_id = 220507
--or 
 select PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID, OBJECT_NAME, OBJECT_TYPE
 from v$session, dba_objects where SID = 9 and PLSQL_ENTRY_OBJECT_ID = object_id
 and owner = 'LUMINX'
 
  select PLSQL_ENTRY_OBJECT_ID, PLSQL_ENTRY_SUBPROGRAM_ID, OBJECT_NAME, OBJECT_TYPE
 from v$session, dba_objects where SID = 1792 and PLSQL_ENTRY_OBJECT_ID = object_id
 and owner = 'WKAB10'


---***************************************GET SQL based on hash value **************
--************************************************************************************************

---GET SQL based on hash value
select st.piece, sql_text, st.sql_id
from v$sqltext_with_newlines st
where st.hash_value = 2730945342
order by 1
--42nmduqvvyu46
select st.piece, sql_text
from v$sqltext_with_newlines st
where st.prev_hash_value = 3082774662
order by 1
1117929848




--**************************SID and OS PROCESS ID **************************************************
--**************************************************************************************************


SELECT	s.saddr, s.sid, s.serial#, s.username,
	s.osuser, s.machine, s.program, s.logon_time, s.status, 
	p.program, p.spid as "OS Process"
FROM v$session s, v$process p
WHERE s.paddr = p.addr and s.sid = 426;

SELECT	s.saddr, s.sid, s.serial#, s.username,
	s.osuser, s.machine, s.program, s.logon_time, s.status, 
	p.program, p.spid as "OS Process"
FROM v$session s, v$process p
WHERE s.paddr = p.addr and  p.spid = 6033520;



SELECT  S.SID, P.SPID FROM V$SESSION S, V$PROCESS P WHERE S.PADDR=P.ADDR(+) AND P.SPID='87053';

SELECT s.SID,s.serial#,s.machine,s.osuser,s.terminal,s.username FROM v$process P LEFT OUTER JOIN v$session s ON P.addr = s.paddr  WHERE P.spid = 47721;


--ps -ef | grep 2445404

SELECT	s.sid,  p.spid as "OS Process"
FROM v$session s, v$process p
WHERE s.paddr = p.addr and s.sid = 131

SELECT	s.sid,  p.spid as "OS Process"
FROM v$session s, v$process p
WHERE s.paddr = p.addr and p.spid = 1941750




--**************************MISC **************************************************
--**************************************************************************************************




A236120/#Loopnow1@wkabprod

system/no734s@wkabdev2


select count(*)
from dba_objects
where status = 'INVALID';



SELECT COUNT(INDEX_NAME) from DBA_INDEXES WHERE owner = 'DRWKAB' and status  = 'UNUSABLE'

SELECT  INDEX_NAME from DBA_INDEXES WHERE owner = 'DRWKAB' and status  = 'UNUSABLE'



select count(*) from v$sql_shared_cursor where sql_id='81gyqvujcduty';

select address, hash_value, loaded_versions from v$sqlarea where sql_id='5c3fxgmvggqyp'; 


--sqlplus
--A236120/#Loopnow2@DR02
A236120/Loopnow1@DPNTP000
SYSTEM/6$TxeQyl@DPNTP000
SYSTEM/no734s@DRSTGC
system/sysdpuat91@DPUAT91

system/no734s@DNTMTRP1



--0. From query above determine sql_id (8h6c002f02mmx) for example
--1. Login to aetnaprod
--2. cd /workability/home/oracle/Monitor/Sql
--3. rm -f  killWaits.sql
--4. sqlplus / as sysdba
--5. spool killWaits.sql
--6. select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id='0pjxbfsjd57yk' and last_call_et>500;
--7. spool off;
--8. @killWaits.sql

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sid = '42';

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where machine = 'AETH\WVMQHEANSIS03';

select *  from v$session where machine = 'AETH\WVMQHEANSIS03';


select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id='4u7xxk6upy8xc'; and last_call_et>500;

ps -ef | grep 48301012
kill -9 48301012











-----------Top 10 sql -------------------
--V$SQLAREA lists statistics on shared SQL area and contains one row per SQL string.
-- It provides statistics on SQL statements that are in memory, parsed, and ready for execution.
-- ***THIS JUST WHAT SITTING IN MEMORY,NOT WHAT BEING EXECUTED NOW ****---
SELECT *
FROM   (SELECT Substr(a.sql_text,1,50) sql_text,
               Trunc(a.disk_reads/Decode(a.executions,0,1,a.executions)) reads_per_execution, 
               a.buffer_gets, 
               a.disk_reads, 
               a.executions, 
               a.sorts,
               a.address
        FROM   v$sqlarea a
        ORDER BY 2 DESC)
WHERE  rownum <= 10;


--select rows_processed from v$sqlarea WHERE SQL_ID = 'gt7yu9phj8mgw';

---------Most CPU Intensive Sessions---------------------------



--NEW works better
SELECT s.sid, s.serial#, s.username, TO_CHAR(s.logon_time, 'mm-dd-yyyy hh24:mi') logon_time, s.last_call_et, st.value, s.sql_hash_value, s.sql_address, sq.sql_text
FROM v$statname sn, v$sesstat st, v$session s, v$sql sq
WHERE 
s.sql_hash_value = sq.hash_value and s.sql_Address = sq.address
AND s.sid = st.sid
AND st.STATISTIC# = sn.statistic#
AND sn.NAME = 'CPU used by this session'
AND s.status = 'ACTIVE'
ORDER BY st.value desc



    








--- MuteX issues*************************************************************************

--ORA-00020: maximum number of processes
-- Sep 2009 '9jqtqhd664g4p' Mute X SQL
select sql_id, count(*) from v$sql_shared_cursor where sql_id in ('bjaq8drw3bg3r','9jqtqhd664g4p') group by sql_id;
-- April 2010'61kn0rk49zm4r' --Mute X SQL
select sql_id, count(*) from v$sql_shared_cursor where sql_id in ('61kn0rk49zm4r','9jqtqhd664g4p') group by sql_id;

select sql_id, count(*) from v$sql_shared_cursor where sql_id in ('9ztzvs07ydfyc') group by sql_id;

--Feb 2011
select sql_id, count(*) from v$sql_shared_cursor where sql_id in ('bjaq8drw3bg3r') group by sql_id;
select trunc(sample_time, 'MI'), count(*) from dba_hist_active_sess_history where sql_id='bjaq8drw3bg3r' and sample_time > trunc(sysdate) group by trunc(sample_time, 'MI') order by 1;



--Find worse guy. On production takes time to run. 
select sql_id, count(*)  from v$sql_shared_cursor group by sql_id;

--ALTER SYSTEM FLUSH SHARED_POOL;
select * from  v$session where program like '%rman%'  
select 'alter system kill session ''' || sid || ',' || serial# || ''';' from v$session where program like '%rman%'  and status <> 'KILLED';
--select 'alter system kill session ''' || sid || ',' || serial# || ''';' from v$session where event like '%from client%' and program='w3wp.exe' and last_call_et>900;
--Mike had to kill PeopleSoft session 
--exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_WKAB_LOOKUP', no_invalidate=>false, cascade=>true);
--exec dbms_stats.gather_table_stats(OWNNAME=>'WKAB10', tabname=>'T_CACHE_COMMAND', force=>TRUE, no_invalidate=>FALSE);

                                                    

 




-------




--

select '--- OLDTRAN ---',
       decode(pxs.qcsid, null, s.sid, pxs.qcsid) as QCSID,
       s.sid,
       p.spid,
       substr(decode(s.type, 'USER', s.username, 'BACKGROUND', 'ORA-' ||bg.name,
 s.username), 1, 15) as username,
       substr(decode(aa.name, 'UNKNOWN', '--', aa.name ), 1, 15) as command,
       s.status,
       substr(s.osuser, 1, 15) as osuser,
       substr(s.machine, 1, 30) as machine,
       substr(s.program, 1, 20) as program,
       substr(s.module, 1, 15) as module,
       substr(s.action, 1, 15) as action,
       s.sql_hash_value,
       s.prev_hash_value,
       sw.event,
       s.lockwait,
       s.row_wait_obj#,
       s.row_wait_row#,
       to_char(s.logon_time, 'YYYY-MM-DD HH24:MI') as logon_time,
       s.last_call_et
from v$session s,
     v$process p,
     v$sess_io sio,
     v$px_session pxs,
     v$bgprocess bg,
     audit_actions aa,
     v$session_wait sw,
     v$transaction t
where s.paddr = p.addr
  and s.sid = sio.sid
  and s.saddr = pxs.saddr (+)
  and s.command = aa.action
  and s.paddr = bg.paddr (+)
  and s.saddr = t.ses_addr
  and to_date(t.start_time, 'MM/DD/YY HH24:MI:SS') < sysdate - 1/1440
  and s.sid = sw.sid
order by sio.consistent_gets, s.username, decode(pxs.qcsid, null, s.sid, pxs.qcsid);

--- OPEN CURSORS issues
select 
   max(a.value) as hwm_open_cur, 
   p.value      as max_open_cur
from 
   v$sesstat a, 
   v$statname b, 
   v$parameter p
where 
   a.statistic# = b.statistic# 
and 
   b.name = 'opened cursors current'
and 
   p.name= 'open_cursors'
group by p.value;


select * from ( select ss.value, sn.name, ss.sid
 from v$sesstat ss, v$statname sn
 where ss.statistic# = sn.statistic#
 and sn.name like '%opened cursors current%'
 order by value desc) where rownum < 11 ;
 
 --- Number of executions of particular query.
 
 SELECT END_INTERVAL_TIME ,EXECUTIONS_DELTA 
FROM dba_hist_sqlstat A, dba_hist_snapshot B
WHERE  A.snap_id = B.snap_id
and A.SQL_ID = 'b9r3yf6pknbkx'
ORDER BY END_INTERVAL_TIME

--- Monitor Mater views

Select * from dba_mview_refresh_times where owner  = 'LX_DAILY'
Select * from dba_mviews where   mview_name = 'WKAB_OVERPAY_MV'

--Determine if any MV being currently refreshed:

select Count(*) from v$mvrefresh;
SELECT *  FROM V$MVREFRESH
SELECT CURRMVOWNER, CURRMVNAME FROM V$MVREFRESH

or

SELECT o.name FROM sys.obj$ o, sys.user$ u, sys.sum$ s
             WHERE o.type# = 42 AND bitand(s.mflags, 8) =8;
             
             SELECT DISTINCT(TRUNC(last_refresh))
FROM dba_snapshot_refresh_times;


Select * from DBA_MVIEW_REFRESH_TIMES


---Good Note: How to monitor the progress of a materialized view refresh (MVIEW) [ID 258021.1]


select *  from dba_mviews where mview_name = 'EMP_UPPER_SUPERVISOR_VW'

select * from dba_refresh_children;
 select * from sys.v_$mvrefresh;



--Monitor long import jobs and inserts

select message, time_remaining/3600 hrs from v$session_longops where sofar <> totalwork;


       SELECT  SUBSTR(sql_text, INSTR(sql_text,'INTO "'),30) table_name
       , rows_processed
       , ROUND( (sysdate-TO_DATE(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes
       , TRUNC(rows_processed/((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_minute
     FROM
         sys.v_$sqlarea
     WHERE
 sql_text like 'INSERT %INTO "%'
       AND command_type = 2
       AND open_versions > 0; 

select
    substr(sql_text,instr(sql_text,'INTO "'),30) table_name,
    rows_processed,
    round((sysdate-
     to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
    trunc(rows_processed/
     ((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_minute
 from 
    sys.v_$sqlarea
 where
      command_type = 2
 and
    open_versions > 0; 
    
    
    
    select
    substr(sql_text,instr(sql_text,'SELECT "'),30) table_name,
    rows_processed,
    round((sysdate-
     to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
    trunc(rows_processed/
     ((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_minute
 from 
    sys.v_$sqlarea
 where
      command_type = 3 and sql_text like 'ClaimWokbasket"%'
 and
    open_versions > 0; 
    
    
        select
    substr(sql_text,instr(sql_text,'SELECT "'),30) table_name,
    rows_processed,
    round((sysdate-
     to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
    trunc(rows_processed/
     ((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_minute
 from 
    sys.v_$sqlarea
 where
   sql_text like 'ClaimWokbasket"%'
 and
    open_versions > 0; 
    


--where command_type not in (
-- 1 --  create table  *
--,2 --  INSERT        *
--,3 --  SELECT        *
--,6 --  UPDATE        *
--,7 --  DELETE        *
--,9 --  create index  *
--,11 -- ALTER INDEX   *
--,26 -- LOCK table    *
--,42 -- ALTER_SESSION (NOT ddl)
----two postings suggest 42 is alter session
--,44 -- COMMIT
--,45 -- rollback
--,46 -- savepoint
--,47 -- PL/SQL BLOCK' or begin/declare *
--,48 -- set transaction   *
--,50 -- explain           *
--,62 -- analyze table     *
--,90 -- set constraints   *
--,170 -- call             *
--,189 -- merge            *





--- Standby apply *****

-- None Prod

SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED, LOG_APPLIED,APPLIED_TIME,
LOG_ARCHIVED-LOG_APPLIED LOG_GAP
FROM
(
SELECT NAME DB_NAME
FROM V$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED
FROM V$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED
FROM V$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES'
),
(
SELECT TO_CHAR(MAX(COMPLETION_TIME),'DD-MON/HH24:MI') APPLIED_TIME
FROM V$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES'
);

select thread#, max(sequence#) "Last Primary Seq Generated"
from v$archived_log val, v$database vdb
where val.resetlogs_change# = vdb.resetlogs_change#
and val.resetlogs_time = vdb.resetlogs_time
group by thread# order by 1;

-- Reg DW standby w21p and New PY standby on NodeA


-- Windsor DW standby 
SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED, LOG_APPLIED,APPLIED_TIME,
LOG_ARCHIVED-LOG_APPLIED LOG_GAP
FROM
(
SELECT NAME DB_NAME
FROM V$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED
FROM V$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED
FROM V$ARCHIVED_LOG WHERE DEST_ID=3 AND APPLIED='YES'
),
(
SELECT TO_CHAR(MAX(COMPLETION_TIME),'DD-MON/HH24:MI') APPLIED_TIME
FROM V$ARCHIVED_LOG WHERE DEST_ID=3 AND APPLIED='YES'
);



-- NodeA Standby

SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED, LOG_APPLIED,APPLIED_TIME,
LOG_ARCHIVED-LOG_APPLIED LOG_GAP
FROM
(
SELECT NAME DB_NAME
FROM V$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED
FROM V$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED
FROM V$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES'
),
(
SELECT TO_CHAR(MAX(COMPLETION_TIME),'DD-MON/HH24:MI') APPLIED_TIME
FROM V$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES'
);

select thread#, max(sequence#) "Last Primary Seq Generated"
from v$archived_log val, v$database vdb
where val.resetlogs_change# = vdb.resetlogs_change#
and val.resetlogs_time = vdb.resetlogs_time
group by thread# order by 1;

-- Reg DW standby w21p and New PY standby on NodeA


-- Windsor DW standby 
SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED, LOG_APPLIED,APPLIED_TIME,
LOG_ARCHIVED-LOG_APPLIED LOG_GAP
FROM
(
SELECT NAME DB_NAME
FROM V$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED
FROM V$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED
FROM V$ARCHIVED_LOG WHERE DEST_ID=3 AND APPLIED='YES'
),
(
SELECT TO_CHAR(MAX(COMPLETION_TIME),'DD-MON/HH24:MI') APPLIED_TIME
FROM V$ARCHIVED_LOG WHERE DEST_ID=3 AND APPLIED='YES'
);






-- PY Windsor Standby
SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED, LOG_APPLIED,APPLIED_TIME,
LOG_ARCHIVED-LOG_APPLIED LOG_GAP
FROM
(
SELECT NAME DB_NAME
FROM V$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED
FROM V$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED
FROM V$ARCHIVED_LOG WHERE DEST_ID=4 AND APPLIED='YES'
),
(
SELECT TO_CHAR(MAX(COMPLETION_TIME),'DD-MON/HH24:MI') APPLIED_TIME
FROM V$ARCHIVED_LOG WHERE DEST_ID=4 AND APPLIED='YES'
);


--- alter system switch logfile ;

--## check what was last applied on primary and standby
--cd $SQLPATH
--sqlplus / as sysdba
--@check_dg_parms.sql
--@check_dg_logs.sql

--On Primary:
	 select max(sequence#) from v$archived_log;
--On Standby:
	select max(sequence#) from v$log_history;
    
--    From Standby  and  Primary to see status and if any issues

-- dgmgrl / 
-- show configuration
-- show database verbose '<DBNAME>_<SERVERNAME>'



select     SID,
            SERIAL#,
            OPNAME,
            START_TIME,
            TOTALWORK,
            sofar,
            ROUND((sofar/totalwork) * 100,2) pct_done,
            sysdate + TIME_REMAINING/3600/24 end_time
from   v$session_longops
where  totalwork > sofar
and    opname NOT LIKE '%aggregate%'
and    opname like 'RMAN%'; 

 
 
 select max(sequence#) as "REDO LOG APPLIED ON STANDBY"
 from v$archived_log
 where applied = 'YES';
 select thread#,
        sequence# as "REDO LOG BEING APPLIED",
        process,
        status,
        block#,
        blocks
 from v$managed_standby
 where sequence# in
 (select max(sequence#) from v$managed_standby);
 
 or
 
 -- MRP is main apply log process
 select process,status,sequence# from v$managed_standby;


--GRP check
SELECT
     SUM(bytes/1024/1024/1024) as "Size(GB)"
     FROM  
   v$flashback_database_logfile;
   
 --  show parameter db_recovery_file_dest_size
--alter system set db_recovery_file_dest_size = 500G scope=both; 

SELECT * from AEDBA.RMAN_HEARTBEAT
   
   
select * from v$database_block_corruption

  select plan_table_output from table (dbms_xplan.display_awr('9myxytcbvk4tk'));
  
  select plan_table_output from table (dbms_xplan.display_awr('590v346cjsrr9',format => 'LAST'));
  select * from table(dbms_xplan.display_cursor(null, null,  'LAST ALLSTATS +COST'))
                               
  
  
    select plan_table_output from table (dbms_xplan.display_awr('590v346cjsrr9',format => 'ADVANCED ALLSTATS LAST'));
    
    select * from table(dbms_xplan.display_cursor('590v346cjsrr9', null, 'basic +note'));
    
    
    SELECT *  FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('590v346cjsrr9'));
 
 
  
  select
  MOUNT_STATUS  ,
  HEADER_STATUS ,
  OS_MB,
  TOTAL_MB ,
  FREE_MB  ,
  substr(NAME,1,20) "Name",
  substr(LABEL,1,10) "Label",
  substr(PATH,1,50) "Path"
from
        v$asm_disk
order by
        path,
        name
;

select name, database_incarnation#, scn, time, GUARANTEE_FLASHBACK_DATABASE from v$restore_point;

select sql_handle, plan_name from DBA_SQL_PLAN_BASELINES where plan_name = 'SQL_PLAN_5kpumfuqurfu1eb6f1b32'


select COUNT(*) from v$session where sql_id='35czkjzdyu3d1';

select * from v$session where sql_id='4vp69m6wkd3c6';

  
  select sql_id,address, hash_value, executions, loads, version_count, invalidations, parse_calls,sql_plan_baseline
from v$sqlarea 
where sql_plan_baseline is not null

select IS_BIND_SENSITIVE  from v$sqlarea where SQL_ID = 'b9366j3sfcqq7'

   select address, hash_value, executions, loads, version_count, invalidations, parse_calls,sql_plan_baseline
from v$sqlarea 
where sql_id = 'bknmd3yxdsgpu';

-- exec aedba.kill_session_by_sqlid('1q300na852nz5')

-- exec aedba.kill_session_by_sid('4533')

-- exec aedba.kill_session_by_sqlid_and_phv('c4fshy7wkw0pm','2317571646')


SELECT * from AEDBA.KILL_SESSION_LOG ORDER BY KILLED_SESSION_DT DESC

select * from dba_sql_plan_baselines where plan_name = 'SQL_PLAN_dtpcbdsj5rppg3ef32e9b'

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id= 'c8k2ba5yy3phm';

select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where sql_id='f2ybn58w7ah14';

select sid from v$session where sql_id='f8q2rgn3cc4xp';


select * from v$session where username='A620237';

select trim(count(*))
from v\$session
WHERE regexp_like(v\$session.SCHEMANAME, '[A|N][0-9]{6}.*') and UPPER(SCHEMANAME) <>  UPPER(OSUSER) and OSUSER NOT LIKE '%aetweb%' and STATUS <> 'KILLED';

select* 
from v$session
WHERE regexp_like(v$session.SCHEMANAME, '[A|N][0-9]{6}.*') and UPPER(SCHEMANAME) <>  UPPER(OSUSER) and OSUSER NOT LIKE '%aetweb%' and PROGRAM NOT LIKE '%Altery%' and STATUS <> 'KILLED';


select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where SCHEMANAME='HRP';
select 'alter system kill session ''' || sid ||  ',' ||serial#|| ''';' from v$session where username='N225100';

USERNAME 

select IS_BIND_SENSITIVE  from v$sqlarea where SQL_ID = '3v50nadq7s20g';

SELECT *   FROM DBA_AUDIT_TRAIL WHERE
TO_CHAR(TIMESTAMP,'MM-DD-YYYY') = '12-14-2021' and USERNAME = 'PROD_DW' order by 
TIMESTAMP desc;

SELECT *   FROM DBA_AUDIT_TRAIL WHERE
TO_CHAR(TIMESTAMP,'MM-DD-YYYY') = '06-30-2021' order by 
TIMESTAMP desc;

select *  from A236120.PACKED_PROFILES;
--exec dbms_shared_pool.purge ('00000000BD5628C0, 3134996154','C');

-- Identify SQL_ID's during pile up based on specific Query type

SELECT b.sid,b.serial#,b.sql_id
FROM   v$sqltext a,v$session b
WHERE  a.sql_text like '%MemberLinkQuery%'
AND a.address = b.sql_address
AND    a.hash_value = b.sql_hash_value
-- and last_call_et>1000
ORDER BY a.piece


select status, to_char(BINDS_XML) from v$sql_monitor where sql_id = '9pb8bptpqqsra' and status <> 'DONE'
  
 -- To kill them
 --BEGIN
 -- FOR r IN (SELECT b.sid,b.serial#
--FROM   v$sqltext a,v$session b
--WHERE  a.sql_text like %MemberLinkQuery%
--AND a.address = b.sql_address
--AND    a.hash_value = b.sql_hash_value
--ORDER BY a.piece)
--  LOOP
--    EXECUTE IMMEDIATE 'alter system kill session ''' || r.sid 
 --     || ',' || r.serial# || '''';
 -- END LOOP;
--END;
--/
  
  
  SELECT TABLESPACE_NAME, BYTES/1024/1024/1024 TBL_SIZE_GB, MAXBYTES/1024/1024/1024 MAX_LIMIT_SIZE_GB, (MAXBYTES/1024/1024/1024 - BYTES/1024/1024/1024) LEFT_BEFORE_MAX_LIMIT_GB,AUTOEXTENSIBLE from DBA_DATA_FILES
WHERE AUTOEXTENSIBLE = 'YES' AND TABLESPACE_NAME NOT IN ('SYSTEM', 'USERS','SYSAUX','TSTPURGE','UNDOTBS1') ORDER BY 4

select tablespace_name,
ROUND(sum(bytes/1024/1024/1024)) FREE_GB
from dba_free_space WHERE TABLESPACE_NAME NOT IN ('SYSTEM', 'USERS','SYSAUX','TSTPURGE','UNDOTBS1','AE_DATA','AE_NDX') 
group by tablespace_name 
order by 2;
  
  -- Execution plan history for give SQL ID
  select
    snap.snap_id,
    snap.instance_number,
    begin_interval_time,
    sql_id,
    plan_hash_value,
    nvl(executions_delta,0) execs,
    (elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
    (buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio
from dba_hist_sqlstat stat, dba_hist_snapshot snap
where sql_id = 'djtufc3x2sfb3'
and snap.snap_id = stat.snap_id
and snap.instance_number = stat.instance_number
and executions_delta > 0
order by 3
  