--TABLES LOCKS--
SELECT SUBSTR(B.OWNER,1,8) "Owner",
B.OBJECT_TYPE,
SUBSTR(B.OBJECT_NAME,1,18) "Object_name" ,
DECODE(A.LOCKED_MODE,0,'None' ,1,'Null' ,
2,'Row-S',3,'Row-X' ,
4,'Share',5,'S/Row-X',
6,'Exclusive') "Locked_Mode",
A.SESSION_ID "Sess_ID",
SUBSTR(A.ORACLE_USERNAME,1,10) "User_name",
A.OS_USER_NAME "OS_User",
to_char(c.logon_time,'YYYY/MM/DD HH24:MI:SS') "Logon_Time",
c.sql_hash_value
FROM V$LOCKED_OBJECT A,DBA_OBJECTS B,v$session c
WHERE A.OBJECT_ID=B.OBJECT_ID
and a.session_id=c.sid
ORDER BY B.OWNER,B.OBJECT_TYPE,B.OBJECT_NAME

--BLOCKING LOCKS--
select s1.username || '@' || s1.machine || ' ( SID=' || s1.sid || ' ) is blocking '
|| s2.username || '@' || s2.machine || ' ( SID=' || s2.sid ||') for last ' || sw.seconds_in_wait ||' seconds.' AS blocking_status
from v$lock l1, v$session s1, v$lock l2, v$session s2, v$session_wait sw where s1.sid=l1.sid and s2.sid=l2.sid
and l1.BLOCK=1 and l2.request > 0 and l1.id1 = l2.id1 and l2.id2 = l2.id2 and
sw.sid = l1.sid;


--SELECT TO_CHAR(SYSDATE, 'HH24:MI:SS') FROM DUAL
